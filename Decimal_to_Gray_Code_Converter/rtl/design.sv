// Binary -> Gray converter, with APB slave + SPI master interfaces.
// Register map: OPERAND (0x0), RESULT (0x2), CONTROL (0x4).
// CONTROL bits: [0]=START (wr-1 pulse), [1]=END (hw set), [7]=INVALID (hw set)

`timescale 1ns/1ns

module converter #(parameter bit[7:0] NO_OF_SPI_BITS = 8)(
  clk, rst_n, paddr, pwdata, psel, penable, miso, pwrite, pready, pslverr, prdata, mosi, cs, sclk
);

  input logic clk;
  input logic rst_n;
  input logic [2:0] paddr;
  input logic [7:0] pwdata;
  input logic psel;
  input logic penable;
  input logic miso;
  input logic pwrite;

  output logic pready;
  output logic pslverr;
  output logic [7:0] prdata;
  output logic mosi;
  output logic cs;
  output logic sclk;

  // internal regs
  reg [7:0] reg_operand, reg_result, reg_control; // addresses: 0, 2, 4
  reg mosi_reg;
  reg [7:0] count_out;
  reg enable;
  reg load;
  reg terminate_cnt;
  reg posedge_sclk, negedge_sclk, cs_delayed;
  reg sclk_delayed;
  reg old_cs;

  //used for 0->1 edge detect on old_cs (= end of SPI transfer)
  reg old_cs_prev;

  // counter (see counter.sv)
  counter counter_inst(
    .clk           (clk),
    .rst_n         (rst_n),
    .load          (load),
    .enable        (enable),
    .count_up_down (1'b0),
    .data_in       (NO_OF_SPI_BITS - 8'd1),
    .count_out     (count_out),
    .terminate_cnt (terminate_cnt)
  );

  // APB read block: return the selected register on prdata
  always @(posedge clk or negedge rst_n)
    if (~rst_n)
      prdata <= 0;
    else if (psel && !penable && !pwrite)
      case (paddr)
        0: prdata <= reg_operand;
        2: prdata <= reg_result;
        4: prdata <= reg_control;
        default: begin
          prdata <= 8'h00;
          $display("[DUT-READ] WARN: read from unallocated address %0d at T=%0t", paddr, $time);
        end
      endcase

  // APB write for OPERAND and RESULT.
  // Writing OPERAND immediately latches the gray equivalent into RESULT,
  // so the value is available as soon as the write completes.
  always @(posedge clk or negedge rst_n)
    if (~rst_n) begin
      reg_operand <= 0;
      reg_result  <= 0;
    end
    else if (psel && !penable && pwrite)
      case (paddr)
        0: begin
          reg_operand <= pwdata;
          reg_result  <= pwdata ^ (pwdata >> 1); // gray = b ^ (b>>1)
          $display("[DUT-WRITE] INFO: Write OPERAND: pwdata=%0d(0x%0h), gray_result=%0d(0x%0h) at T=%0t",
                   pwdata, pwdata, pwdata ^ (pwdata >> 1), pwdata ^ (pwdata >> 1), $time);
        end
        2: begin
          // RESULT is read-only, DUT replies with PSLVERR below
          $display("[DUT-WRITE] WARN: Write attempt on RESULT register (read-only) at T=%0t", $time);
        end
        // addr 4 is handled by its own always block
        default: begin
          if (paddr != 4)
            $display("[DUT-WRITE] WARN: Write to unallocated address %0d at T=%0t", paddr, $time);
        end
      endcase

  // CONTROL register (addr 4). Kept as a single block so that sw writes and
  // hw-driven bit updates don't race on the same register.
  //   bit 0  -> START : set by sw, auto-clears 1 clk later (single pulse)
  //   bit 1  -> END   : set by hw when a full SPI transfer finished
  //   bit 7  -> INVALID: set by hw if CS went back high before counter = 0
  always @(posedge clk or negedge rst_n)
    if (~rst_n) begin
      reg_control <= 0;
    end
    else if (psel && !penable && pwrite && paddr == 4) begin
      // sw write wins over the hw updates on the same cycle
      reg_control <= pwdata;
      $display("[DUT-CTRL] INFO: Write CONTROL: pwdata=0x%0h (START=%b, END=%b, INVALID=%b) at T=%0t",
               pwdata, pwdata[0], pwdata[1], pwdata[7], $time);
    end
    else begin
      //auto-clear START one clk after it was raised
      if (reg_control[0] == 1'b1) begin
        reg_control[0] <= 1'b0;
        $display("[DUT-CTRL] INFO: Auto-reset START bit at T=%0t", $time);
      end

      // END: CS just went back high after all 8 bits were shifted out
      if (old_cs_prev == 0 && old_cs == 1 && terminate_cnt == 1) begin
        reg_control[1] <= 1'b1;
        $display("[DUT-CTRL] INFO: SPI transmission COMPLETE - END bit set at T=%0t", $time);
      end

      // INVALID: CS went back high but the counter was not yet at 0
      if (old_cs_prev == 0 && old_cs == 1 && terminate_cnt == 0) begin
        reg_control[7] <= 1'b1;
        $display("[DUT-CTRL] WARN: SPI transmission INCOMPLETE - INVALID bit set at T=%0t", $time);
      end
    end

  // delayed copy of old_cs, used for the 0->1 edge detect
  always @(posedge clk or negedge rst_n)
    if (~rst_n)
      old_cs_prev <= 1;
    else
      old_cs_prev <= old_cs;

  // SCLK runs only during a transfer (old_cs=0). When idle it is held low.
  always @(posedge clk or negedge rst_n)
    if (~rst_n)
      sclk <= 0;
    else if (old_cs == 0)
      sclk <= ~sclk;
    else
      sclk <= 0;

  // old_cs: 0 during transfer, 1 when idle.
  // pulled low by START, returns to 1 when the counter hits 0.
  always @(posedge clk or negedge rst_n)
    if (~rst_n)
      old_cs <= 1;
    else if (reg_control[0] == 1)
      old_cs <= 0;
    else if (count_out == 0)
      old_cs <= 1;

  // one-clk delayed copy, used below to stretch cs by an extra cycle
  always @(posedge clk or negedge rst_n)
    if (~rst_n)
      cs_delayed <= 1;
    else
      cs_delayed <= old_cs;

  // the cs actually driven on the bus is stretched by 1 clk
  assign cs = cs_delayed & old_cs;

  // counter control
  assign enable = (~old_cs & negedge_sclk) | load;
  assign load   = reg_control[0];

  // MOSI: shift out reg_result one bit per posedge sclk
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      mosi_reg <= 1'b0;
    end
    else if (old_cs == 0 && posedge_sclk) begin
      mosi_reg <= reg_result[count_out];
      $display("[DUT-SPI] INFO: Transmit bit[%0d]=%b from reg_result=0x%0h at T=%0t",
               count_out, reg_result[count_out], reg_result, $time);
    end
  end

  // MOSI is driven from mosi_reg while cs is low, tri-stated otherwise.
  // We gate on the extended cs (not old_cs) on purpose: old_cs drops as soon
  // as the counter hits 0, which would pull mosi off the bus one clk too
  // early. The extended cs stays low for one more cycle so the slave gets
  // to sample the last bit properly.
  assign mosi = (cs == 1) ? 1'bz : mosi_reg;

  // sclk edge detection (used to align counter enable with bit boundaries)
  always @(posedge clk or negedge rst_n)
    if (~rst_n)
      sclk_delayed <= 0;
    else
      sclk_delayed <= sclk;

  assign posedge_sclk =  sclk & ~sclk_delayed;
  assign negedge_sclk = ~sclk &  sclk_delayed;

  // pready - single clk pulse, raised one cycle after psel is seen
  always @(posedge clk or negedge rst_n)
    if (~rst_n)
      pready <= 0;
    else if (pready == 1)
      pready <= 0;
    else if (psel && !penable)
      pready <= 1;

  // pslverr - raised on invalid address or on a write to RESULT (read-only)
  always @(posedge clk or negedge rst_n)
    if (~rst_n)
      pslverr <= 0;
    else if (pslverr == 1)
      pslverr <= 0;
    else if (psel && !penable && (!(paddr == 0 || paddr == 2 || paddr == 4) || (paddr == 2 && pwrite == 1))) begin
      pslverr <= 1;
      $display("[DUT-ERR] WARN: PSLVERR activated - paddr=%0d, pwrite=%b at T=%0t", paddr, pwrite, $time);
    end

endmodule

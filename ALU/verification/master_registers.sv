`include "FIFO_buffer.sv"

module master_registers #(
parameter ADDR_WIDTH = 5,
parameter DATA_WIDTH = 32,
parameter REG_WIDTH  = 8
) (
  input                         clk             , // System clock
  input                         preset          , // System reset
  input                         p_valid_wr      ,  
  input                         fifo_re         , 
  input                         overflow        , 
  input                         done            , 
  input                         fail            , 
  input                         bsy             ,    
  input       [DATA_WIDTH -1:0] pwdata          , 
  input       [ADDR_WIDTH -1:0] paddr           , 
  output                        empty           , 
  output reg  [REG_WIDTH -1:0]  reg_data        , 
  output reg  [REG_WIDTH -1:0]  reg_operations  , 
  output reg  [REG_WIDTH -1:0]  reg_status      , 
  output reg  [REG_WIDTH -1:0]  reg_divider     , 
  output reg  [REG_WIDTH -1:0]  reg_control     , 
  output reg  [REG_WIDTH -1:0]  reg_mask        , 
  output reg  [REG_WIDTH -1:0]  reg_config      , 
  output      [8:0]             fifo_data         

);

// ----------------
// Local parameters
// ----------------
localparam ADDR_DATA        = 5'h00;
localparam ADDR_OPERATIONS  = 5'h04;
localparam ADDR_STATUS      = 5'h08;
localparam ADDR_DIVIDER     = 5'h0C;         
localparam ADDR_CONTROL     = 5'h10;
localparam ADDR_MASK        = 5'h14;
localparam ADDR_CONFIG      = 5'h18;

// --------------------------
// Declare of wires/registers
// --------------------------

wire fifo_we;
wire clear_fifo;
wire clear_irq;
wire full;
reg [8:0] data_in;
wire [4:0] irq_fields;

// Debug counters - how many DATA and OP writes we've seen
reg [7:0] count_data = 'b0;
reg [7:0] count_operations = 'b0;

wire write_data_sig;
wire write_operations_sig;

assign write_data_sig = p_valid_wr && (paddr == 5'h00);
assign write_operations_sig = p_valid_wr && (paddr == 5'h04);

// Single FIFO holds both operands and opcodes - writes from DATA or OPERATIONS
// addresses both push into the same buffer; op_controller uses data[8] to tell them apart
assign fifo_we = p_valid_wr && ((paddr == 5'h00) || (paddr == 5'h04));
assign clear_fifo = reg_control[0];
assign clear_irq  = reg_control[1];

// Build the IRQ field vector that gets OR'd into the STATUS register.
// FULL fires only when we try to write DATA while FIFO is already full.
assign irq_fields = {                                   (overflow),  // bit[4] - OVERFLOW
                                                (fifo_re && empty),  // bit[3] - EMPTY
                      (p_valid_wr && (paddr == ADDR_DATA) && full),  // bit[2] - FULL
                                                            (fail),  // bit[1] - FAIL
                                                            (done)}; // bit[0] - DONE

// Build the 9-bit FIFO word. Operations get bit[8]=1 so op_controller knows
// they're opcodes and not operands. DATA writes keep bit[8]=0.
always @(*) begin
  case(paddr)
    ADDR_DATA:        data_in <= pwdata[7:0];
    ADDR_OPERATIONS:  data_in <= {1'b1,pwdata[7:0]};
    default:          data_in <= 'h0;
  endcase
end

always @(posedge write_data_sig) begin
  count_data <= count_data + 1;
end

always @(posedge write_operations_sig) begin
  count_operations <= count_operations + 1;
end

FIFO_buffer #(
  .DATA_WIDTH(9),
  .DEPTH(256)
) fifo (
  .clk(clk),
  .clear(clear_fifo),
  .we(fifo_we),
  .re(fifo_re),
  .data_in(data_in),
  .data_out(fifo_data),
  .empty(empty),
  .full(full)
);

// -------------
// DATA register
// -------------
always @(posedge clk or posedge preset) begin
  if(preset)                              reg_data <= 'h0; else
  if(p_valid_wr && (paddr == ADDR_DATA)) begin
    reg_data <= pwdata[7:0];
    $display("T=%0t [REGS] FIFO write DATA=%0d (0x%0h), count_data=%0d", $time, pwdata[7:0], pwdata[7:0], count_data+1);
  end
end

// -------------------
// OPERATIONS register
// -------------------
always @(posedge clk or posedge preset) begin
  if(preset)                                   reg_operations <= 'h0; else
  if(p_valid_wr && (paddr == ADDR_OPERATIONS)) begin
    reg_operations <= pwdata[7:0];
    $display("T=%0t [REGS] FIFO write OP=0x%0h, count_ops=%0d", $time, pwdata[7:0], count_operations+1);
  end
end

// ----------------
// DIVIDER register
// ----------------
always @(posedge clk or posedge preset) begin
  if(preset)                                reg_divider <= 'hFF;  else
  if(p_valid_wr && (paddr == ADDR_DIVIDER)) reg_divider <= pwdata[7:0];
end

// ----------------
// CONTROL register
// ----------------
// START and STOP (bits 2/3) are self-clearing pulses - they are asserted for one
// cycle by software and the HW clears them right away so they look like edges.
// CLEAR_FIFO / CLEAR_IRQ also clear themselves after the ack propagates.
always @(posedge clk or posedge preset) begin
  if(preset)                                reg_control      <= 'h0;         else
  if(clear_fifo)                            reg_control[0]   <= 1'b0;        else
  if(clear_irq)                             reg_control[1]   <= 1'b0;        else
  if(p_valid_wr && (paddr == ADDR_CONTROL)) begin
    reg_control <= pwdata[7:0];
    $display("T=%0t [REGS] CONTROL write=0x%0h (CLEAR_FIFO=%b CLEAR_IRQ=%b START=%b STOP=%b)", $time, pwdata[7:0], pwdata[0], pwdata[1], pwdata[2], pwdata[3]);
  end
  if(reg_control[2])                         reg_control[2]  <= 1'b0;
  if(reg_control[3])                         reg_control[3]  <= 1'b0;
end

// ---------------
// CONFIG register
// ---------------
always @(posedge clk or posedge preset) begin
  if(preset)                                reg_config <= 'h0; else 
  if(p_valid_wr &&( paddr == ADDR_CONFIG))  reg_config <= pwdata[7:0];
end

// -----------------
// IRQ MASK register
// -----------------
always @(posedge clk or posedge preset) begin
  if(preset)                              reg_mask <= 'h0; else
  if(p_valid_wr && (paddr == ADDR_MASK))  reg_mask <= pwdata[7:0];
end

// ----------------------
// Update STATUS register
// ----------------------
// Bits [4:0] latch sticky flags - once set they stay 1 until software writes
// CLEAR_IRQ. Bit [5] (BSY) is a live mirror of the controller's busy signal,
// not sticky, so we only refresh it when no new flag is being OR'd in.
always @(posedge clk or posedge preset) begin
  if(preset)     reg_status       <= 'h0;                          else
  if(clear_irq)  reg_status[4:0]  <= 'h0;                          else
  if(irq_fields) begin
    reg_status[4:0]  <= reg_status[4:0] | irq_fields;
    $display("T=%0t [REGS] STATUS update: irq_fields=0x%0h -> status=0x%0h (DONE=%b FAIL=%b FULL=%b EMPTY=%b OVF=%b)", $time, irq_fields, reg_status[4:0] | irq_fields, irq_fields[0], irq_fields[1], irq_fields[2], irq_fields[3], irq_fields[4]);
  end else
                 reg_status[5]    <= bsy;
end
endmodule
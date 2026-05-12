`timescale 1ns/1ns
module interrupt_controller
  #(
  parameter ADDR_WIDTH = 6,
  parameter DATA_WIDTH = 32,
  parameter IRQ_WIDTH  = 3
  )
  (
    input clk,
    input reset,

    //APB signals
    input  		[ADDR_WIDTH - 1:0]  paddr,
    input  		[DATA_WIDTH - 1:0]  pwdata,
    output reg 	[DATA_WIDTH - 1:0]	prdata,
    input             				pwrite,
    input             				penable,
    input            				psel,
    output            				pready,
    output            				pslverr,

    //output data signals
    output reg  [IRQ_WIDTH - 1:0] 	intr_code, //irq
    output reg						valid //irq_flag
  );

  reg [7:0] reg_int_pri0;
  reg [7:0] reg_int_pri1;
  reg [7:0] reg_int_pri2;
  reg [7:0] reg_int_pri3;
  reg [7:0] reg_int_pri4;
  reg [7:0] reg_int_pri5;
  reg [7:0] reg_int_pri6;
  reg [7:0] reg_int_pri7;

  reg [7:0]  reg_ext_int; //RW
  reg [7:0]  reg_enable_interrupts;  //RW
  //wire [31:0] reg_cfg;
  wire [7:0] reg_result; //RO reg

  //reg valid;
  //reg [2:0] chnel;
  //reg winner_flag;

  wire cfg; //after configuring all registers

  // intermodular wires
  wire p_valid_wr;
  wire ext_int_written; // pulse when EXT_INT register is written (new servicing cycle)

  reg [2:0] state;
  reg [7:0] pri_state;

    //STATEMACHINE
  parameter [2:0] WAIT = 3'b000;
  parameter [2:0] PROCESS = 3'b001;
  parameter [2:0] VALIDATE = 3'b010;

  parameter [7:0] PRI0 = 8'b0000_0000;
  parameter [7:0] PRI1 = 8'b0000_0001;
  parameter [7:0] PRI2 = 8'b0000_0010;
  parameter [7:0] PRI3 = 8'b0000_0100;
  parameter [7:0] PRI4 = 8'b0000_1000;
  parameter [7:0] PRI5 = 8'b0001_0000;
  parameter [7:0] PRI6 = 8'b0010_0000;
  parameter [7:0] PRI7 = 8'b0100_0000;
  parameter [7:0] DECIDE = 8'b1000_0000; // state after scanning all priorities

  reg [3:0] max_priority_intr;
  reg [2:0] intr_to_serve;                // The interrupt to be served
  reg [7:0] served_interrupts;            // Already served interrupts mask

  assign p_valid_wr = psel & penable & pwrite ;
  assign ext_int_written = p_valid_wr && (paddr == 'h09);

  assign pready = psel && penable;
  assign pslverr = pready && ((paddr == 6'h00) || (paddr > 6'h09 && paddr < 6'h10) || (paddr > 6'h11));

  assign cfg = ~((|reg_int_pri0) && (|reg_int_pri1) && (|reg_int_pri2) && (|reg_int_pri3) && (|reg_int_pri4) && (|reg_int_pri5) && (|reg_int_pri6) && (|reg_int_pri7));

  always @(posedge clk or negedge reset) begin
    if (~reset) begin
       state <= WAIT;
       pri_state <= PRI0;
       intr_code <= 3'b000; // Initialize interrupt code
      	valid <= 1'b0;
       served_interrupts <= 'b0;
       max_priority_intr <= 'b0;
    end
    else begin
        case (state)
            WAIT: begin
              valid <= 1'b0;
               // A new write on EXT_INT marks the start of a new servicing cycle,
               // so we clear the served mask — old "served" bits no longer apply
              if (ext_int_written) begin
                 served_interrupts <= 'b0;
                 $display("[DUT] %0t WAIT: EXT_INT written, clearing served_interrupts", $time);
              end
              // Leave WAIT only if there's at least one interrupt that is asserted,
              // enabled and not yet served, and configuration is complete
              if ( |(reg_ext_int & reg_enable_interrupts & ~served_interrupts) && ~cfg) begin
                    state <= PROCESS;
                    $display("[DUT] %0t WAIT->PROCESS: ext_int=%08b, enable=%08b, served=%08b, cfg=%0b", $time, reg_ext_int, reg_enable_interrupts, served_interrupts, cfg);
                end else
                  state <= WAIT;
            end

            PROCESS: begin
                // max_priority_intr is updated with the maximum priority
                //We select the highest priority that has not been served yet and is not masked

                //for (int i = 0; i < 8; i = i + 1) begin
                //    if (reg_enable_interrupts[i] && (max_priority_intr < priority_interrupts[i])) begin
                //        max_priority_intr <= priority_interrupts[i];
                //        intr_to_serve <= i; // Save the interrupt to be served
                //    end
                //end
                case(pri_state)

                  PRI0: begin
                    //max_priority_intr <= 0;
                    // if (interrupt is enabled && interrupt is asserted && interrupt has highest priority && interrupt was not served yet)
                    if (reg_enable_interrupts[0] && reg_ext_int[0] && (max_priority_intr < reg_int_pri0) && (~served_interrupts[0])) begin
                        max_priority_intr <= reg_int_pri0;
                        intr_to_serve <= 0;  // Save the interrupt to be served
                    end
                    pri_state <= PRI1;
                  end

                  PRI1: begin
                    if (reg_enable_interrupts[1] && reg_ext_int[1] && (max_priority_intr < reg_int_pri1) && (~served_interrupts[1])) begin
                        max_priority_intr <= reg_int_pri1;
                        intr_to_serve <= 1; // Save the interrupt to be served
                    end
                    pri_state <= PRI2;
                  end

                  PRI2: begin
                    if(reg_enable_interrupts[2] && reg_ext_int[2] && (max_priority_intr < reg_int_pri2)&& (~served_interrupts[2])) begin
                        max_priority_intr <= reg_int_pri2;
                        intr_to_serve <= 2; // Save the interrupt to be served
                    end
                    pri_state <= PRI3;
                  end
                  PRI3: begin
                    if (reg_enable_interrupts[3] && reg_ext_int[3] && (max_priority_intr < reg_int_pri3) && (~served_interrupts[3])) begin
                       max_priority_intr <= reg_int_pri3;
                       intr_to_serve <= 3;  // Save the interrupt to be served
                    end
                    pri_state <= PRI4;
                  end

                  PRI4: begin
                    if (reg_enable_interrupts[4] && reg_ext_int[4] && (max_priority_intr < reg_int_pri4) && (~served_interrupts[4])) begin
                        max_priority_intr <= reg_int_pri4;
                        intr_to_serve <= 4; // Save the interrupt to be served
                    end
                    pri_state <= PRI5;
                  end
                  PRI5: begin
                    if (reg_enable_interrupts[5] && reg_ext_int[5] && (max_priority_intr < reg_int_pri5) &&(~served_interrupts[5])) begin
                        max_priority_intr <= reg_int_pri5;
                        intr_to_serve <= 5; // Save the interrupt to be served
                    end
                    pri_state <= PRI6;
                  end
                  PRI6: begin
                    if (reg_enable_interrupts[6] && reg_ext_int[6] && (max_priority_intr < reg_int_pri6) && (~served_interrupts[6])) begin
                        max_priority_intr <= reg_int_pri6;
                        intr_to_serve <= 6; // Save the interrupt to be served
                    end
                    pri_state <= PRI7;
                  end

                  PRI7: begin
                    if (reg_enable_interrupts[7] && reg_ext_int[7] && (max_priority_intr < reg_int_pri7) && (~served_interrupts[7])) begin
                        max_priority_intr <= reg_int_pri7;
                        intr_to_serve <= 7;
                    end
                    pri_state <= DECIDE;  // go to DECIDE to let PRI7 non-blocking settle
                  end

                  DECIDE: begin
                     // By now all PRI0..PRI7 non-blocking assignments have settled, so
                     // max_priority_intr and intr_to_serve reflect the actual winner
                    if ((max_priority_intr > 0) && (~served_interrupts[intr_to_serve])) begin
                       state <= VALIDATE;
                       served_interrupts[intr_to_serve] <= 1'b1; // mark as served so we don't pick it again
                       $display("[DUT] %0t DECIDE: serving interrupt %0d, served_mask=%08b", $time, intr_to_serve, served_interrupts);
                    end else begin
                       // nothing eligible — go back to WAIT and let new inputs arrive
                       state <= WAIT;
                       $display("[DUT] %0t DECIDE: no eligible interrupt found, returning to WAIT", $time);
                    end
                    pri_state <= PRI0;
                  end
                  default: begin
                    pri_state <= PRI0;
                  end
                endcase
            end

            VALIDATE: begin
                // drive irq_code and raise valid pulse for 1 cycle
              	pri_state <= PRI0;
                valid <= 1;
                intr_code <= intr_to_serve;
                state <= WAIT;
              	max_priority_intr <= 0; // reset for next scan
                $display("[DUT] %0t VALIDATE: outputting intr_code=%0d, valid=1", $time, intr_to_serve);
            end
        endcase
    end
  end

  always @(posedge clk)
	begin
	  case (paddr)
	    6'h11:   prdata <= {24'b0, reg_enable_interrupts};
	    6'h01:   prdata <= {24'b0, reg_int_pri0};
	    6'h02:   prdata <= {24'b0, reg_int_pri1};
	    6'h03:   prdata <= {24'b0, reg_int_pri2};
	    6'h04:   prdata <= {24'b0, reg_int_pri3};
	    6'h05:   prdata <= {24'b0, reg_int_pri4};
	    6'h06:   prdata <= {24'b0, reg_int_pri5};
	    6'h07:   prdata <= {24'b0, reg_int_pri6};
	    6'h08:   prdata <= {24'b0, reg_int_pri7};
      	6'h09:   prdata <= {24'b0, reg_ext_int};//RW register
      	6'h10:   prdata <= {24'b0, reg_result};
      	//6'h11:   prdata <= {8'b0, priority_interrupts};
	    default: prdata <= 32'h0;
	  endcase
	end

  assign reg_result[2:0] = intr_code;
  assign reg_result[6:3] = 0;
  assign reg_result[7] = valid;

    //PRIORITY registers:

  // Log every valid APB write — useful when chasing register-level bugs
  always @(posedge clk)
    if(p_valid_wr)
      $display("[DUT] %0t APB_WRITE: addr=0x%02h, wdata=0x%02h", $time, paddr, pwdata[7:0]);

  always @(posedge clk or negedge reset)
    if(~reset)			reg_int_pri0 <= 8'b0; else
    if(p_valid_wr && (paddr == 'h01))	reg_int_pri0 <= pwdata[7:0];

  always @(posedge clk or negedge reset)
    if(~reset)          reg_int_pri1 <= 8'b0; else
    if(p_valid_wr && (paddr == 'h02))   reg_int_pri1 <= pwdata[7:0];

  always @(posedge clk or negedge reset)
    if(~reset)          reg_int_pri2 <= 8'b0; else
    if(p_valid_wr && (paddr == 'h03))   reg_int_pri2 <= pwdata[7:0];

  always @(posedge clk or negedge reset)
    if (~reset)          reg_int_pri3 <= 8'b0; else
    if(p_valid_wr && (paddr == 'h04))   reg_int_pri3 <= pwdata[7:0];

  always @(posedge clk or negedge reset)
    if(~reset)          reg_int_pri4 <= 8'b0; else
    if(p_valid_wr && (paddr == 'h05))   reg_int_pri4 <= pwdata[7:0];

  always @(posedge clk or negedge reset)
    if(~reset)          reg_int_pri5 <= 8'b0; else
    if(p_valid_wr &&(paddr == 'h06))   reg_int_pri5 <= pwdata[7:0];

  always @(posedge clk or negedge reset)
    if(~reset)          reg_int_pri6 <= 8'b0; else
    if(p_valid_wr && (paddr == 'h07))   reg_int_pri6 <= pwdata[7:0];

  always @(posedge clk or negedge reset)
    if(~reset)          reg_int_pri7 <= 8'b0; else
    if(p_valid_wr && (paddr == 'h08))   reg_int_pri7 <= pwdata[7:0];

    //INTERRUPT ENABLE register:
  always @(posedge clk or negedge reset)
    if(~reset)                          reg_enable_interrupts <= 8'b0; else
      if(p_valid_wr && (paddr == 'h11))   reg_enable_interrupts <= pwdata[7:0];

  always @(posedge clk or negedge reset)
    if(~reset)                          reg_ext_int <= 8'b0; else
    if(p_valid_wr && (paddr == 'h09))   reg_ext_int <= pwdata[7:0];

endmodule





`include "master_registers.sv"
`include "op_controller.sv"

module rtl_ALU #(
parameter ADDR_WIDTH    = 5,
parameter DATA_WIDTH    = 32,
parameter RESULT_WIDTH  = 16,
parameter REG_WIDTH     = 8
) (
    // System interface
    input   clk       ,   // System clock; used on the APB interface
    input   rst_n     ,   // System reset; Active low

    // APB interface
    input                           psel      ,   // Select; Indicates the start of the first transfer phase
    input                           penable   ,   // Enable; Indicates the start of the second transfer phase
    input       [ADDR_WIDTH -1:0]   paddr     ,   // Address
    input                           pwrite    ,   // Write/Read enable
    input       [DATA_WIDTH -1:0]   pwdata    ,   // Write data
    output                          pready    ,   // Ready; Indicates that the Slave has completed the transfer
    output reg  [DATA_WIDTH -1:0]   prdata    ,   // Read data
    output                          pslverr   ,   // Slave error; Is asserted together with pready if the Slave encountered an error during a transfer

    // Result interface
    output  [RESULT_WIDTH -1:0]     result    ,   // Result of the operation
    output                          valid     ,   // Valid signal

    // Interrupt interface
    output  irq           // Interrupt request
);


// Local parameters
localparam ADDR_DATA        = 5'h00;
localparam ADDR_OPERATIONS  = 5'h04;
localparam ADDR_STATUS      = 5'h08;
localparam ADDR_DIVIDER     = 5'h0C;         
localparam ADDR_CONTROL     = 5'h10;
localparam ADDR_MASK        = 5'h14;
localparam ADDR_CONFIG      = 5'h18;

// Declare registers/wires

wire preset = ~rst_n;

// Registers
wire [REG_WIDTH -1:0] reg_data;        // Data register - WO
wire [REG_WIDTH -1:0] reg_operations;  // Operations register - WO


wire [REG_WIDTH -1:0] reg_status;      // Status register - RO


wire [REG_WIDTH -1:0] reg_divider;     // Clock divider register - RW
wire [REG_WIDTH -1:0] reg_control;     // Control register - RW

                                  
wire [REG_WIDTH -1:0] reg_config;      // Configuration register - RW


wire [REG_WIDTH -1:0] reg_mask;        // Interrupt request mask - RW

reg reg_freeze;

// Wires
wire p_valid_wr;
wire [8:0] fifo_data;
wire fail;
wire done;
wire empty;
wire bsy;
wire fifo_re;
wire start;
wire stop;
wire overflow;

assign pready  = psel & penable;

// Slave error: either address is above the last valid register (0x18 = CONFIG),
// or the two LSBs are non-zero (APB requires 4-byte aligned addresses)
assign pslverr = pready && ((paddr > 5'h18) || (|paddr[1:0]));

// APB write is valid only when the transfer is in phase-2 and the FSM
// isn't frozen in the middle of a computation
assign p_valid_wr = psel & penable & pwrite & ~reg_freeze & pready;

// Raise interrupt when any STATUS flag has its matching MASK bit set
assign irq = |(reg_status[4:0] & reg_mask[4:0]);

// Debug logs for IRQ and pslverr
always @(posedge clk) begin
  if(pslverr)
    $display("T=%0t [DUT] *** PSLVERR *** addr=0x%0h (>0x18 or unaligned)", $time, paddr);
  if(irq)
    $display("T=%0t [DUT] *** IRQ ACTIVE *** status=0x%0h mask=0x%0h", $time, reg_status, reg_mask);
end

assign start = reg_control[2];
assign stop  = reg_control[3];

// APB read mux - DATA/OPERATIONS are WO so they read as zero.
// The upper bits are padded with zeros, each register only exposes its used bits.
always @(posedge clk) begin
  case(paddr)
    ADDR_DATA:          prdata <= 32'h0;
    ADDR_OPERATIONS:    prdata <= 32'h0;
    ADDR_STATUS:        prdata <= {26'h0, reg_status[5:0]};
    ADDR_DIVIDER:       prdata <= {24'h0, reg_divider[7:0]};
    ADDR_CONTROL:       prdata <= {28'h0, reg_control[3:0]};
    ADDR_MASK:          prdata <= {27'h0, reg_mask[4:0]};
    ADDR_CONFIG:        prdata <= {25'h0, reg_config[6:0]};
    default:            prdata <= 32'h0;
  endcase
end

// reg_freeze blocks APB writes while a computation is running, so software
// can't change operands mid-flight. It must clear when the op finishes
// (done/fail/overflow) or is aborted (stop), otherwise writes stay blocked forever.
always @(posedge clk or posedge preset) begin
  if(preset)                    reg_freeze <= 1'b0; else
  if(stop)                    begin reg_freeze <= 1'b0; $display("T=%0t [DUT] reg_freeze cleared (STOP)", $time); end else
  if(done || fail || overflow) begin reg_freeze <= 1'b0; $display("T=%0t [DUT] reg_freeze cleared (done=%b fail=%b ovf=%b)", $time, done, fail, overflow); end else
  if(start)                   begin reg_freeze <= 1'b1; $display("T=%0t [DUT] reg_freeze set (START)", $time); end
end

master_registers #(
 .ADDR_WIDTH(5),
 .DATA_WIDTH(32),
 .REG_WIDTH(8)
) registers(
  .clk(clk),
  .preset(preset),
  .pwdata(pwdata),
  .paddr(paddr),
  .overflow(overflow),
  .empty(empty),
  .done(done),
  .fail(fail),
  .bsy(bsy),
  .reg_data(reg_data),
  .reg_operations(reg_operations),
  .reg_status(reg_status),
  .reg_divider(reg_divider),
  .reg_control(reg_control),
  .reg_mask(reg_mask),
  .reg_config(reg_config),
  .fifo_re(fifo_re),
  .p_valid_wr(p_valid_wr),
  .fifo_data(fifo_data)
);

op_controller #(
.RESULT_WIDTH(16),
.REG_WIDTH(8),
.DATA_WIDTH(9)
) controller(
  .clk(clk),
  .preset(preset),
  .start(start),
  .stop(stop),
  .empty(empty),
  .divider(reg_divider),
  .reg_config(reg_config),
  .result(result),
  .valid(valid),
  .fifo_re(fifo_re),
  .overflow(overflow),
  .bsy(bsy),
  .data(fifo_data),
  .done(done),
  .fail(fail)
);
    
endmodule
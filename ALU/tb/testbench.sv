`include "apb_interface.sv"
`include "irq_interface.sv"
`include "output_interface.sv"
`include "test_initial_t1.sv"
// `include "test_initial_t2.sv"

module testbench();
  
  bit clk = 1'b0;
  bit rst_n;
  
  wire 			psel;
  wire 			penable;
  wire [4:0] 	paddr;
  wire 			pwrite;
  wire [31:0]   pwdata;
  wire 			pready;
  wire [31:0]   prdata;
  wire 			pslverr;
  wire [15:0]	result;
  wire			valid;
  wire			irq;
  
  apb_interface apb_intf(clk, rst_n);
  
  assign psel    = apb_intf.psel;
  assign penable = apb_intf.penable;
  assign paddr   = apb_intf.paddr;
  assign pwrite  = apb_intf.pwrite;
  assign pready  = apb_intf.pready;
  assign prdata  = apb_intf.prdata;
  assign pslverr = apb_intf.pslverr;  
  
  output_interface output_intf(clk, rst_n);
  
  assign result  = output_intf.result;
  assign valid   = output_intf.valid;
  
  irq_interface irq_intf(clk, rst_n);
  
  assign irq     = irq_intf.irq;
  
  always 
      #10 clk <= ~clk;

  
  initial begin
    clk<=0;
    rst_n <= 1'b1;
    #500;
    rst_n <= 1'b0;
    #500;
    rst_n <= 1'b1;
    #200000;
    $stop;
  end
  
  initial begin
  	$dumpfile("dump.vcd");
  	$dumpvars;
  end
  test_initial_t1 test1(apb_intf, output_intf, irq_intf );
//  test_initial_t2 test2(apb_intf, output_intf, irq_intf );
  rtl_ALU #(
    .ADDR_WIDTH(5),
    .DATA_WIDTH(32),
    .RESULT_WIDTH(16),
    .REG_WIDTH(8)
  ) DUT (
    .clk    (		clk),
    .rst_n  (		rst_n),
    .psel   (		apb_intf.psel),
    .penable(		apb_intf.penable),
    .paddr  (		apb_intf.paddr),
    .pwrite (		apb_intf.pwrite),
    .pwdata (		apb_intf.pwdata),
    .pready (		apb_intf.pready),
    .prdata (		apb_intf.prdata),
    .pslverr(		apb_intf.pslverr),
    .result (		output_intf.result),
    .valid  (		output_intf.valid),
    .irq    (		irq_intf.irq)
  );
  
  
endmodule
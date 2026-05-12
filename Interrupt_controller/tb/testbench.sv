//tbench_top or testbench top, this is the top most file, in which DUT(Design Under Test) and Verification environment are connected.
`timescale 1ns/1ns
//including interface and testcase files
`include "apb_interface.sv"
`include "out_interface.sv"

// NOTE: a single testcase is active at a time — uncomment the one you want to run
// and comment out the others.
//`include "write_read_reg_test.sv"
//`include "all_intr_en_test.sv"
//`include "one_intr_en_test.sv"
//`include "random_test.sv"
`include "addr_invalid_test.sv"

module testbench;

  parameter ADDR_WIDTH = 6;
  parameter DATA_WIDTH = 32;
  parameter IRQ_WIDTH  = 3;

  //clock and reset signal declaration
  reg clk;
  reg reset;

  wire [ADDR_WIDTH - 1:0]	paddr;
  wire [DATA_WIDTH - 1:0]	pwdata;
  wire [DATA_WIDTH - 1:0]	prdata;
  wire						pwrite;
  wire						penable;
  wire						psel;
  wire						pready;
  wire						pslverr;

  wire [IRQ_WIDTH - 1:0]	intr_code;
  wire						valid;

  //clock generation
  always #5 clk = ~clk;

  // reset Generation
  initial begin
    clk <= 1;
    //reset <= 1;
   // #10 reset <= 0;
    reset <= 0;
    #20 reset <=1;
    #8000 reset <=0;
  end


  //creatinng instance of interface, inorder to connect DUT and testcase
  apb_interface apb_intf(clk,reset);
  out_interface out_intf(clk, reset);

  //Testcase instance, interface handle is passed to test as an argument
 //test t(apb_intf, out_intf);
  // test1 t(apb_intf, out_intf);
//    test2 t(apb_intf, out_intf);
//    test3 t(apb_intf, out_intf);
  test4 t(apb_intf, out_intf);

  // DUT instance, interface signals are connected to the DUT ports
  interrupt_controller #(
    .IRQ_WIDTH  (IRQ_WIDTH ),
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
  ) DUT (
    .clk    	(clk               ),
    .reset  	(reset             ),
    .paddr  	(apb_intf.paddr    ),
    .pwdata 	(apb_intf.pwdata   ),
    .prdata 	(apb_intf.prdata   ),
    .pwrite 	(apb_intf.pwrite   ),
    .penable	(apb_intf.penable  ),
    .psel   	(apb_intf.psel     ),
    .pready 	(apb_intf.pready   ),
    .pslverr	(apb_intf.pslverr  ),
    .intr_code	(out_intf.irq),
    .valid    	(out_intf.irq_flag    )
   );
  /*
  apb_dummy #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
  ) i_apb_dummy (
    .clk(clk),
    .reset(reset),
    .paddr(paddr),
    .pwdata(pwdata),
    .prdata(prdata),
    .pwrite(pwrite),
    .penable(penable),
    .psel(psel),
    .pready(pready),
    .pslverr(pslverr)
   );
  */

  //enabling the wave dump
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();

  //  #10000
  //  $finish();
  end
endmodule
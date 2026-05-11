`timescale 1ns/1ps
//tbench_top or testbench top, this is the top most file, in which DUT(Design Under Test) and Verification environment are connected.

//including interface and testcase files
  parameter ADDR_WIDTH = 2;
  parameter DATA_WIDTH = 8;

`include "out_interface.sv"
`include "apb_interface.sv"
//Particular testcase can be run by uncommenting, and commenting the rest
//`include "random_test.sv"
//`include "test_register_access.sv"
//`include "test_left_signal.sv"
//`include "test_registers.sv"
//`include "test_hazard.sv"
//`include "test_wipers.sv"
//`include "test_washer.sv"
//`include "test_right_signal.sv"
//`include "test_high_beam.sv"
//`include "test_flash.sv"
//`include "test_wipers_washer.sv"
//`include "test_flash_highbeam.sv"
//`include "wr_rd_test.sv"
//`include "default_rd_test.sv"
//`include "test_wipers_25.sv"
//`include "test_wipers_75.sv"
//`include "test_wipers_100.sv"
//`include "test_wipers_0.sv"
`include "test_combined.sv"


module testbench;

  //clock and reset signal declaration
  bit clk;
  bit reset;

  //clock generation
  always #5 clk = ~clk;


  //reset Generation
  initial begin
    reset = 1;
    #35 reset =0;
  end


  //creating instance of interface, in order to connect DUT and testcase
  out_interface output_interface(clk,reset);
  apb_interface apbinterface(clk,reset);

  //Testcase instance, interface handle is passed to test as an argument
  test t1(output_interface , apbinterface);

  // DUT instantiation
  controller_board #(ADDR_WIDTH, DATA_WIDTH) dut (
    .clk(clk),
    .reset(reset),
    .paddr_i( apbinterface.paddr),
    .pwrite_i(apbinterface.pwrite),
    .penable_i(apbinterface.penable),
    .pwdata_i(apbinterface.pwdata),
    .prdata_o(apbinterface.prdata),
    .high_beam_o(output_interface.high_beam),
    .left_signal_o(output_interface.left_signal),
    .right_signal_o(output_interface.right_signal),
    .flash_o(output_interface.flash),
    .washer_o(output_interface.washer),
    .wipers_o(output_interface.wipers),
    .psel_i(apbinterface.psel),
    .pready_o(apbinterface.pready)
  );

  //enabling the wave dump
  initial begin
    $dumpfile("dump.vcd"); $dumpvars;
  end
endmodule

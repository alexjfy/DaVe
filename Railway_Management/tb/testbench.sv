`include "uvm_macros.svh"
import uvm_pkg::*;

`define CLK_PERIOD 10


`include "../verification/defines.sv"

`timescale 1ns/1ns

`include "../interfaces/trains_interface.sv"
`include "../interfaces/semaphore_interface.sv"
`include "../tests/zoo_test_base.sv"
`include "../tests/single_train_request_test.sv"
`include "../tests/odd_even_priority_test.sv"
`include "../tests/same_parity_priority_test.sv"
`include "../tests/all_requests_test.sv"
`include "../tests/same_train_repeated_test.sv"
`include "../tests/stress_test.sv"

module top();
  logic clk, reset;
  wire t1, t2, t3, t4, t5, t6, even_semaphore, odd_semaphore;
  
  //create interfaces instances
  trains_interface intf_trains();
  assign intf_trains.clk = clk;
  assign intf_trains.rst = reset;
  // assign reset       = intf_trains.rst;
  assign t1          = intf_trains.t_1;
  assign t2          = intf_trains.t_2;
  assign t3          = intf_trains.t_3;
  assign t4          = intf_trains.t_4;
  assign t5          = intf_trains.t_5;
  assign t6          = intf_trains.t_6;
  
  semaphore_interface intf_semaphore();
  assign intf_semaphore.clk            = clk;
  assign intf_semaphore.rst            = reset;
  assign intf_semaphore.even_semaphore = even_semaphore;
  assign intf_semaphore.odd_semaphore  = odd_semaphore;
  
  initial begin
    //generate clock signal
	  clk <= 1;
	  forever begin
      #(`CLK_PERIOD/2)  
      clk <= ~clk;
    end
	end
  
  initial begin
    //generate reset signal
    reset <= 1;
    repeat (15) @(posedge clk);
    reset <= 0;
  end
  
   initial
  	begin
      //add interfaces to the UVM database
      uvm_config_db#(virtual trains_interface)::set(null, "*", "trains_interface", intf_trains);
      uvm_config_db#(virtual semaphore_interface)::set(null, "*", "semaphore_interface", intf_semaphore);

      //run desired test
      run_test();
  	end

  //instantiate the DUT
  railway_management DUT(
    .clk_i            (clk),
    .reset_i          (reset),
    .t1_i	            (t1),
    .t2_i	            (t2),
    .t3_i	            (t3),
    .t4_i	            (t4),
    .t5_i	            (t5),
    .t6_i	            (t6),
    .odd_semaphore_o  (odd_semaphore),
    .even_semaphore_o (even_semaphore));

endmodule
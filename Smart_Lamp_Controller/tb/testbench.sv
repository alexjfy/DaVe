`include "uvm_macros.svh"
import uvm_pkg::*;

`define CLK_PERIOD 10

`define WIDTH 8

`timescale 1ns/1ns

`include "../verification/defines.sv"
`include "../tests/auto_mode_test.sv"
`include "../tests/manual_mode_test.sv"
`include "../tests/global_test.sv"
`include "../tests/sensor_limit_values_test.sv"
`include "../tests/sensor_test.sv"
`include "../tests/long_push_button_test.sv"
`include "../rtl/design.sv"
				
module top();
  logic clk;
  logic reset;
  logic valid, ready, button;
  wire [1:0] light_level;
  wire [7:0] brightness;
  
  sensor_interface sensor_if();
  assign sensor_if.clk = clk;
  assign sensor_if.rst = reset;
  assign brightness = sensor_if.brightness;
  assign sensor_if.ready = ready;
  assign valid = sensor_if.valid;
  
  button_interface  button_if();
  assign button_if.clk = clk;
  assign button_if.rst = reset;
  assign button = button_if.button;
  
  lamp_interface  lamp_if();
  assign lamp_if.clk = clk;
  assign lamp_if.rst = reset;
  assign lamp_if.light_level = light_level;
  
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
    reset <= 0;
    repeat (15) @(posedge clk);
    reset <= 1;
  end
  
  initial begin
    #10000
    $finish();
  end
  
  initial begin
    uvm_config_db#(virtual interface button_interface)::set(null, "*", "button_interface", button_if);
    uvm_config_db#(virtual interface sensor_interface)::set(null, "*", "sensor_interface", sensor_if);
    uvm_config_db#(virtual interface lamp_interface)::set(null, "*", "lamp_interface", lamp_if);

    //run desired test
    run_test();
  end  

  //instantiate the DUT
  design_test #(
    .WIDTH(`WIDTH)
  )
  DUT_design
  (
    .clk        (clk),
    .reset      (reset),
    .button     (button),
    .sensor     (brightness),
    .valid      (valid),
    .ready      (ready),
    .light_level(light_level)
  );

endmodule
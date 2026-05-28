`include "uvm_macros.svh"
import uvm_pkg::*;

`include "data.sv"
`include "control.sv"
`include "../interfaces/button_interface.sv"
`include "../interfaces/sensor_interface.sv"
`include "../interfaces/lamp_interface.sv"

module design_test
#(parameter WIDTH = 'd8)
  (
  input             clk,
  input             reset,
  input [WIDTH-1:0] sensor,
  input             valid,
  input logic       button,
  output            ready,
  output [1:0]      light_level
);
  wire w_short_push;
  wire w_long_push;
  wire w_off;
  wire w_on0;
  wire w_on1;
  wire w_on2;
  wire w_auto;
  wire w_disable;
  wire done;			
  
  data #(
    .WIDTH(WIDTH)
  )
  DUT_data
  (
    .clk        (clk),
    .reset      (reset),
    .button     (button),
    .sensor     (sensor),
    .valid      (valid),
    .light_level(light_level),
    .s_off      (w_off),
    .s_on0      (w_on0),
    .s_on1      (w_on1),
    .s_on2      (w_on2),
    .s_auto     (w_auto),
    .s_disable  (w_disable),
    .short_push (w_short_push),
    .long_push  (w_long_push),
	  .done       (done)
  );
  
  control #(
    .WIDTH(WIDTH)
  )
  DUT_control
  (
    .clk       (clk),
    .reset     (reset),
    .short_push(w_short_push),
    .long_push (w_long_push),
    .s_off     (w_off),
    .s_on0     (w_on0),
    .s_on1     (w_on1),
    .s_on2     (w_on2),
    .s_auto    (w_auto),
    .s_disable (w_disable),
    .ready     (ready),
	  .done      (done)
  );
endmodule


////---------------
//// Interface bind
////---------------
//bind design_test interfata_lampa interfata_lampa0(
//  .clk(clk),
//  .rst(reset),
//  .lampa(light_level));
//
//bind design_test interfata_sensor interfata_sensor0(
//  .clk(clk),
//  .rst(reset),
//  .date(sensor),
//  .valid(valid),
//  .ready(ready));
//
//bind design_test interfata_button interfata_button0(
//  .clk(clk),
//  .rst(reset),
//  .button(button));
  
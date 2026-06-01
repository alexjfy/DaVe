`include "uvm_macros.svh"
import uvm_pkg::*;

`define CLK_PERIOD 10

`timescale 1ns/1ns

`include "../verification/defines.sv"

`include "../interfaces/actuator_interface.sv"
`include "../interfaces/button_interface.sv"
`include "../interfaces/sensor_interface.sv"

`include "../tests/sensor_limit_values_test.sv"
`include "../tests/temperature_test.sv"
`include "../tests/humidity_test.sv"
`include "../tests/luminosity_test.sv"
`include "../tests/sensor_test.sv"
`include "../tests/frequent_button_test.sv"

module top();
  logic clk;
  parameter DATA_WIDTH = 6;
	logic reset_i;
	wire enable;
	wire valid;
	wire [DATA_WIDTH-1:0] temperature;
	wire [DATA_WIDTH  :0] humidity;
	wire [DATA_WIDTH+3:0] luminous;
	wire heat;
	wire AC;
	wire dehumidifier;
	wire blinds;
	wire ready;
  
  sensor_interface intf_sensor();
  assign intf_sensor.clk_i   = clk;
  assign intf_sensor.ready_o = ready;
  assign intf_sensor.reset_i = reset_i;
  assign valid       = intf_sensor.valid_i;
  assign luminous    = intf_sensor.luminous_intensity_i;
  assign temperature = intf_sensor.temperature_i;
  assign humidity    = intf_sensor.humidity_i;
                              
  
  button_interface intf_button();
  assign intf_button.clk_i   = clk;
  assign intf_button.reset_i = reset_i;
  assign enable = intf_button.enable_i;
                                 
  actuator_interface intf_actuator();
  assign intf_actuator.clk_i          = clk;
  assign intf_actuator.reset_i        = reset_i;
  assign intf_actuator.heat_o         = heat;
  assign intf_actuator.AC_o           = AC;
  assign intf_actuator.dehumidifier_o = dehumidifier;
  assign intf_actuator.blinds_o       = blinds;
  
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
    reset_i <= 1;
    repeat (15) @(posedge clk);
    reset_i <= 0;
  end
  
  initial begin
    #10000
    $finish();
  end
  
  initial begin
    uvm_config_db#(virtual interface sensor_interface)::set(null, "*", "sensor_interface", intf_sensor);
    uvm_config_db#(virtual interface button_interface)::set(null, "*", "button_interface", intf_button);
    uvm_config_db#(virtual interface actuator_interface)::set(null, "*", "actuator_interface", intf_actuator);

    //run desired test
    run_test();
  end

  //instantiate the DUT
  ambient DUT(
	.clk_i                 (clk         ),
	.reset_i               (reset_i     ),
	.enable_i              (enable      ),
	.temperature_i         (temperature ),
	.humidity_i            (humidity    ),
	.luminous_intensity_i  (luminous    ),
	.valid_i			         (valid       ),
	.heat_o		             (heat        ),
  .AC_o                  (AC          ),
	.dehumidifier_o        (dehumidifier),
	.blinds_o              (blinds      ),
	.ready_o               (ready       )
);


endmodule
`ifndef __actuator_intf
`define __actuator_intf

interface actuator_interface;
  logic clk_i; 
  logic reset_i;
  logic heat_o;
  logic AC_o;
  logic dehumidifier_o;
  logic blinds_o;
  
  // Assertions

  // heat and AC cannot be on at the same time
  property temperature_control;
    @(posedge clk_i) disable iff (reset_i!==0)
    (AC_o + heat_o <=1);
  endproperty
  
  temperature_control_assertion: assert property (temperature_control) 
    else `uvm_error("ACTUATOR_INTERFACE", $sformatf("temperature_control_assertion failed: heat = %0d, AC = %0d", heat_o, AC_o));
    TEMPERATURE_CONTROL: cover property (temperature_control);
      
endinterface

`endif
`ifndef __sensor_coverage
`define __sensor_coverage

class sensor_coverage extends uvm_component;
  
  //the component is added to the database of this project;
  `uvm_component_utils(sensor_coverage)
  
  //declare pointer to the monitor
  sensor_agent_monitor p_monitor;
  
  covergroup sensor_cg;
    option.per_instance = 1;
    sensor_state : coverpoint p_monitor.sensor_trans.sensor{
      bins off           = {[193:254]};
      bins on0           = {[127:190]};
      bins on1           = {[65:126]};
      bins on2           = {[1:62]};
      bins limit_value_0 = {0};
      bins limit_value_1 = {63};
      bins limit_value_2 = {64};
      bins limit_value_3 = {127};
      bins limit_value_4 = {128};
      bins limit_value_5 = {191};
      bins limit_value_6 = {192};
      bins limit_value_7 = {255};
    }
  endgroup
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
    $cast(p_monitor, parent);
    sensor_cg = new();
  endfunction
  
endclass : sensor_coverage

`endif
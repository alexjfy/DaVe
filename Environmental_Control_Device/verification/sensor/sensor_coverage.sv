`ifndef __sensor_coverage
`define __sensor_coverage

class sensor_coverage extends uvm_component;
  
  //the component is added to the database of this project;
  `uvm_component_utils(sensor_coverage)
  
  //declare pointer to the monitor
  sensor_agent_monitor p_monitor;
  
  covergroup sensor_cg;
    option.per_instance = 1;
    temperature_cp : coverpoint p_monitor.sensor_trans.temperature{
      bins heat_on        = {[0:21]};
      bins heat_limit_on  = {22};
      bins heat_limit_off = {23};
      bins heat_off       = {[24:40]};
    }
    ac_cp : coverpoint p_monitor.sensor_trans.temperature{
      bins ac_off       = {[0:21]};
      bins ac_limit_off = {22};
      bins ac_stable    = {[23:24]};
      bins ac_limit_on  = {25};
      bins ac_on        = {[24:40]};
    }
    humidity_cp : coverpoint p_monitor.sensor_trans.humidity{
      bins dehumidifier_off       = {[0:34]};
      bins dehumidifier_limit_off = {35};
      bins dehumidifier_stable    = {[36:49]};
      bins dehumidifier_limit_on  = {50};
      bins dehumidifier_on        = {[51:100]};
    }
    luminous_intensity_cp : coverpoint p_monitor.sensor_trans.luminous_intensity{
      bins blinds_open        = {[0:199]};
      bins blinds_limit_open  = {200};
      bins blinds_stable      = {[201:699]};
      bins blinds_limit_close = {700};
      bins blinds_closed      = {[701:900]};
    }
  endgroup
  
  //declare the class constructor;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    $cast(p_monitor, parent);
    sensor_cg = new();
  endfunction
  
endclass : sensor_coverage

`endif
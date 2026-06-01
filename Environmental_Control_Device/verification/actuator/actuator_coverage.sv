`ifndef __actuator_coverage
`define __actuator_coverage

class actuator_coverage extends uvm_component;
  
  //the component is added to the database of this project;
  `uvm_component_utils(actuator_coverage)
  
  //declare pointer to the monitor
  actuator_agent_monitor p_monitor;
  
  covergroup actuator_cg;
    option.per_instance = 1;
    heat         : coverpoint p_monitor.actuator_trans.Heat_i;
    ac           : coverpoint p_monitor.actuator_trans.AC_i;
    blinds       : coverpoint p_monitor.actuator_trans.Blinds_i;
    dehumidifier : coverpoint p_monitor.actuator_trans.Dehumidifier_i;
  
    actuator_cross : cross heat, ac, blinds, dehumidifier{
      ignore_bins heat_and_ac_on = binsof(heat) intersect {1} &&
                                   binsof(ac) intersect {1};
    }
  endgroup
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
    $cast(p_monitor, parent);
    actuator_cg = new();
  endfunction
  
endclass: actuator_coverage

`endif
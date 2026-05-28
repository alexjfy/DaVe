`ifndef __lamp_coverage
`define __lamp_coverage

class lamp_coverage extends uvm_component;

  //the component is added to the database of this project;
  `uvm_component_utils(lamp_coverage)
  
  //declare pointer to the monitor
  lamp_agent_monitor p_monitor;
  
  covergroup lamp_state_cg;
    option.per_instance = 1;
    lamp_state : coverpoint p_monitor.lamp_trans.light_level_out;
  endgroup

  //declare the class constructor;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    $cast(p_monitor, parent);
    lamp_state_cg = new();
  endfunction
  
endclass : lamp_coverage

`endif
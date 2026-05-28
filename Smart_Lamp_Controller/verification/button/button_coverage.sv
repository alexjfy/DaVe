`ifndef __button_coverage
`define __button_coverage

class button_coverage extends uvm_component;

  //the component is added to the database of this project;
  `uvm_component_utils(button_coverage)
  
  //declare pointer to the monitor
  button_agent_monitor p_monitor;
  
  covergroup button_cg;
    option.per_instance = 1;
    button_state : coverpoint p_monitor.button_trans.button;
  endgroup
  
  //declare the class constructor;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    $cast(p_monitor, parent);
    button_cg = new();
  endfunction
  
endclass : button_coverage

`endif
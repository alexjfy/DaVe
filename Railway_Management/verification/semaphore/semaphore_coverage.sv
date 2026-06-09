`ifndef __semaphore_coverage
`define __semaphore_coverage

class semaphore_coverage extends uvm_component;
  
  //the component is added to the database of this project;
  `uvm_component_utils(semaphore_coverage)
  
  //declare pointer to the monitor
  semaphore_agent_monitor p_monitor;
  
  covergroup semaphore_states_cg;
    option.per_instance = 1;
    even_semaphore_state_cp: coverpoint p_monitor.semaphore_trans.even_semaphore_state;
    odd_semaphore_state_cp: coverpoint p_monitor.semaphore_trans.odd_semaphore_state;
  endgroup
  
  //declare the class constructor;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    $cast(p_monitor, parent);
    semaphore_states_cg = new();
  endfunction
  
endclass : semaphore_coverage

`endif
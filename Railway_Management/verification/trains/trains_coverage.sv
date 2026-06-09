`ifndef __trains_coverage
`define __trains_coverage

class trains_coverage extends uvm_component;
  
  //the component is added to the database of this project;
  `uvm_component_utils(trains_coverage)
  
  //declare pointer to the monitor
  trains_agent_monitor p_monitor;
  
  covergroup trains_requests_cg;
    option.per_instance = 1;
    t1: coverpoint p_monitor.trains_trans.t1_i;
    t2: coverpoint p_monitor.trains_trans.t2_i;
    t3: coverpoint p_monitor.trains_trans.t3_i;
    t4: coverpoint p_monitor.trains_trans.t4_i;
    t5: coverpoint p_monitor.trains_trans.t5_i;
    t6: coverpoint p_monitor.trains_trans.t6_i;
    
    requests_cross : cross t1, t2, t3, t4, t5, t6;
  endgroup
  
 //declare the class constructor;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    $cast(p_monitor, parent);
    trains_requests_cg = new();
  endfunction
  
endclass : trains_coverage

`endif
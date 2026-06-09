`ifndef __environment
`define __environment

// typedef class scoreboard;

`include "railway_state_coverage.sv"
`include "trains/trains_agent.sv"
`include "semaphore/semaphore_agent.sv"
`include "scoreboard.sv"

class environment extends uvm_env;
  
  //the environment is added to the database of this project;
  `uvm_component_utils(environment)
  
  //declare interfaces
  virtual trains_interface    trains_vif;
  virtual semaphore_interface semaphore_vif;
  
  //declare agents
  trains_agent    trains_agent_inst;  
  semaphore_agent semaphore_agent_inst;
  
  //declare scoreboard
  scoreboard IO_scorboard;
  
  //declare the class constructor;
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    trains_agent_inst    = trains_agent::type_id::create("trains_agent_inst", this);
    semaphore_agent_inst = semaphore_agent::type_id::create("semaphore_agent_inst", this);
    IO_scorboard         = scoreboard::type_id::create("IO_scorboard", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    `uvm_info("ENVIRONMENT", "Connecting components", UVM_DEBUG);

    assert(uvm_resource_db#(virtual trains_interface)::read_by_name(get_full_name(), "trains_interface", trains_vif)) 
    else `uvm_fatal("ENVIRONMENT", {"Virtual interface must be set for: ",get_full_name(),".trains_vif"})
    
    assert(uvm_resource_db#(virtual semaphore_interface)::read_by_name(get_full_name(), "semaphore_interface", semaphore_vif)) 
    else `uvm_fatal("ENVIRONMENT", {"Virtual interface must be set for: ",get_full_name(),".semaphore_interface"})
    
    trains_agent_inst.trains_agent_monitor_port.connect(IO_scorboard.trains_scb_imp);
    semaphore_agent_inst.semaphore_agent_monitor_port.connect(IO_scorboard.semaphore_scb_imp);
  endfunction: connect_phase
  
endclass : environment

`endif
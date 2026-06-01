`ifndef __verification_environment
`define __verification_environment

// typedef class scoreboard;
`include "sensor/sensor_agent.sv"
`include "actuator/actuator_agent.sv"
`include "button/button_agent.sv"
`include "global_coverage.sv"
`include "scoreboard.sv"

class environment extends uvm_env;
  
  //the environment is added to the database of this project;
  `uvm_component_utils(environment)
  
  //declare interfaces
  virtual actuator_interface actuator_vif;
  virtual button_interface   button_vif;
  virtual sensor_interface   sensor_vif;
  
  //declare agents
  button_agent   button_agent_inst;
  sensor_agent   sensor_agent_inst;
  actuator_agent actuator_agent_inst;
  
  //declare scoreboard
  scoreboard IO_scorboard;
  
  //declare the class constructor;
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    button_agent_inst = button_agent::type_id::create("button_agent_inst", this);
    sensor_agent_inst = sensor_agent::type_id::create("sensor_agent_inst", this);
    actuator_agent_inst = actuator_agent::type_id::create("actuator_agent_inst", this);
    IO_scorboard = scoreboard::type_id::create("IO_scorboard", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    `uvm_info("ENVIRONMENT", "Connecting components", UVM_DEBUG);
    
    assert(uvm_resource_db#(virtual actuator_interface)::read_by_name(get_full_name(), "actuator_interface", actuator_vif))
    else `uvm_fatal("ENVIRONMENT", {"Virtual interface must be set for: ",get_full_name(),".actuator_vif"})
    
    assert(uvm_resource_db#(virtual button_interface)::read_by_name(get_full_name(), "button_interface", button_vif)) 
    else `uvm_fatal("ENVIRONMENT", {"Virtual interface must be set for: ",get_full_name(),".button_vif"})
    
    assert(uvm_resource_db#(virtual sensor_interface)::read_by_name(get_full_name(), "sensor_interface", sensor_vif)) 
    else `uvm_fatal("ENVIRONMENT", {"Virtual interface must be set for: ",get_full_name(),".sensor_vif"});
    
	  button_agent_inst.button_agent_monitor_port.connect(IO_scorboard.button_scb_imp);
    sensor_agent_inst.sensor_agent_monitor_port.connect(IO_scorboard.sensor_scb_imp);
    actuator_agent_inst.actuator_agent_monitor_port.connect(IO_scorboard.actuator_scb_imp);
  endfunction: connect_phase
  
endclass : environment

`endif
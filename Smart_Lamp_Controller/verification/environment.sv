`ifndef __verification_environment
`define __verification_environment

//declare data type to keep the state of the reference model of the lamp control module
typedef enum {OFF, AUTO, MANUAL} lamp_modes;

`include "lamp/lamp_agent.sv"
`include "button/button_agent.sv"
`include "sensor/sensor_agent.sv"
`include "lamp_state_coverage.sv"
`include "scoreboard.sv"

class environment extends uvm_env;
  
  //the environment is added to the database of this project;
  `uvm_component_utils(environment)
  
  //declare interfaces
  virtual sensor_interface sensor_if;
  virtual lamp_interface   lamp_if;
  virtual button_interface button_if;
  
  //declare agents
  lamp_agent   lamp_agent_inst; 
  button_agent button_agent_inst;
  sensor_agent sensor_agent_inst;
  
  //declare scoreboard
  scoreboard IO_scorboard;
  
  //declare the class constructor;
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    lamp_agent_inst = lamp_agent::type_id::create("lamp_agent_inst", this);
    button_agent_inst = button_agent::type_id::create("button_agent_inst", this);
    sensor_agent_inst = sensor_agent::type_id::create("sensor_agent_inst", this);
    IO_scorboard = scoreboard::type_id::create("IO_scorboard", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    `uvm_info("ENVIRONMENT", "Connecting components", UVM_DEBUG);
    
    assert(uvm_resource_db#(virtual sensor_interface)::read_by_name(get_full_name(), "sensor_interface", sensor_if)) 
    else `uvm_fatal("ENVIRONMENT", {"Virtual interface must be set for: ",get_full_name(),".sensor_if"})
    
    assert(uvm_resource_db#(virtual lamp_interface)::read_by_name(get_full_name(), "lamp_interface", lamp_if)) 
    else `uvm_fatal("ENVIRONMENT", {"Virtual interface must be set for: ",get_full_name(),".lamp_if"})
    
    assert(uvm_resource_db#(virtual button_interface)::read_by_name(get_full_name(), "button_interface", button_if)) 
    else `uvm_fatal("ENVIRONMENT", {"Virtual interface must be set for: ",get_full_name(),".button_if"});
    
    sensor_agent_inst.sensor_agent_monitor_port.connect(IO_scorboard.sensor_scb_imp);
    lamp_agent_inst.lamp_agent_monitor_port.connect(IO_scorboard.lamp_scb_imp);
    button_agent_inst.button_agent_monitor_port.connect(IO_scorboard.button_scb_imp);
  endfunction
  
endclass : environment

`endif
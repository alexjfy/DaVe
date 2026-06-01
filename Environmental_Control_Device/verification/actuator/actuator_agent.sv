`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __actuator_agent
`define __actuator_agent

//include the dependencies used by the agent
typedef class actuator_agent_monitor;
`include "actuator_coverage.sv"
`include "actuator_transaction.sv"
`include "actuator_agent_monitor.sv"

class actuator_agent extends uvm_agent;
  
  //the agent is added to the database of this project;
  `uvm_component_utils (actuator_agent)
  
  //instantiate the agent's base components: monitor;
  actuator_agent_monitor actuator_agent_monitor_inst;
  
  //declare the communication port between the agent and the scoreboard/reference environment;
  uvm_analysis_port #(actuator_transaction) actuator_agent_monitor_port;
  
  //declare a field that specifies whether the agent is active or passive;
  local int is_active = 0;
  
  //declare the class constructor;
  function new (string name = "actuator_agent", uvm_component parent = null);
    super.new (name, parent);
    actuator_agent_monitor_port = new("actuator_agent_monitor_port", this);
  endfunction 
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    actuator_agent_monitor_inst = actuator_agent_monitor::type_id::create ("actuator_agent_monitor_inst", this);
  endfunction
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    actuator_agent_monitor_port = actuator_agent_monitor_inst.actuator_monitor_port;
  endfunction
  
endclass : actuator_agent

`endif
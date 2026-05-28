`ifndef __lamp_agent
`define __lamp_agent

//include the dependencies used by the agent
typedef class lamp_agent_monitor;
`include "lamp_transaction.sv"
`include "lamp_coverage.sv"
`include "lamp_agent_monitor.sv"

class lamp_agent extends uvm_agent;

  //the agent is added to the database of this project;
  `uvm_component_utils (lamp_agent)
  
  //instantiate the agent's base components: the driver, monitor, and sequencer;
  lamp_agent_monitor  lamp_agent_monitor_inst;
  
  //declare the communication port between the agent and the scoreboard/reference environment;
  uvm_analysis_port #(lamp_transaction) lamp_agent_monitor_port;
  
  //declare the class constructor;
  function new (string name = "lamp_agent", uvm_component parent = null);
    super.new (name, parent);
    lamp_agent_monitor_port = new("lamp_agent_monitor_port", this);
  endfunction 
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    lamp_agent_monitor_inst = lamp_agent_monitor::type_id::create ("lamp_agent_monitor_inst", this);
  endfunction
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    lamp_agent_monitor_port = lamp_agent_monitor_inst.lamp_monitor_port;  
  endfunction
  
endclass : lamp_agent

`endif
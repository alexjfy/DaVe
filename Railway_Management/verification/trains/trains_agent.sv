`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __trains_agent
`define __trains_agent

//include the dependencies used by the agent
`include "trains_transaction.sv"
`include "trains_coverage.sv"
`include "trains_agent_driver.sv"
`include "trains_agent_monitor.sv"

class trains_agent extends uvm_agent;
  
  //the agent is added to the database of this project;
  `uvm_component_utils (trains_agent)
  
  //instantiate the agent's base components: the driver, monitor, and sequencer;
  trains_agent_driver                 trains_agent_driver_inst;
  trains_agent_monitor                trains_agent_monitor_inst;
  uvm_sequencer #(trains_transaction) trains_agent_sequencer_inst;
  
  //declare the communication port between the agent and the scoreboard/reference environment;
  uvm_analysis_port #(trains_transaction) trains_agent_monitor_port;
  
  //declare a field that specifies whether the agent is active or passive;
  local int is_active = 1;
  
  //declare the class constructor;
  function new (string name = "trains_agent", uvm_component parent = null);
    super.new (name, parent);
    trains_agent_monitor_port = new("trains_agent_monitor_port", this);
  endfunction 
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    trains_agent_monitor_inst = trains_agent_monitor::type_id::create ("trains_agent_monitor_inst", this);
    if (is_active==1) begin
      trains_agent_sequencer_inst = uvm_sequencer#(trains_transaction)::type_id::create ("trains_agent_sequencer_inst", this);
      trains_agent_driver_inst = trains_agent_driver::type_id::create ("trains_agent_driver_inst", this);
    end

  endfunction
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    trains_agent_monitor_port = trains_agent_monitor_inst.trains_monitor_port;
    if (is_active==1)begin
      trains_agent_driver_inst.seq_item_port.connect (trains_agent_sequencer_inst.seq_item_export);
    end
  endfunction
  
endclass : trains_agent

`endif
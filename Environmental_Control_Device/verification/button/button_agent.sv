`ifndef __button_agent
`define __button_agent

//include the dependencies used by the agent
typedef class button_agent_monitor;
`include "button_transaction.sv"
`include "button_coverage.sv"
`include "button_agent_driver.sv"
`include "button_agent_monitor.sv"

class button_agent extends uvm_agent;
  
  //the agent is added to the database of this project;
  `uvm_component_utils (button_agent)
  
  //instantiate the agent's base components: the driver, monitor, and sequencer;
  button_agent_driver button_agent_driver_inst;
  button_agent_monitor button_agent_monitor_inst;
  uvm_sequencer #(button_transaction) button_agent_sequencer_inst;
  
  //declare the communication port between the agent and the scoreboard/reference environment;
  uvm_analysis_port #(button_transaction) button_agent_monitor_port;
  
  //declare a field that specifies whether the agent is active or passive;
  local int is_active = 1;
  
  //declare the class constructor;
  function new (string name = "agent_buton", uvm_component parent = null);
    super.new (name, parent);
    button_agent_monitor_port = new("button_agent_monitor_port", this);
  endfunction 
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    button_agent_monitor_inst = button_agent_monitor::type_id::create ("button_agent_monitor_inst", this);
    if (is_active==1) begin
      button_agent_sequencer_inst = uvm_sequencer#(button_transaction)::type_id::create ("button_agent_sequencer_inst", this);
      button_agent_driver_inst = button_agent_driver::type_id::create ("button_agent_driver_inst", this);
    end
  endfunction
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    button_agent_monitor_port = button_agent_monitor_inst.button_monitor_port;
    if (is_active==1)begin
      button_agent_driver_inst.seq_item_port.connect (button_agent_sequencer_inst.seq_item_export);
    end
  endfunction
  
endclass : button_agent

`endif
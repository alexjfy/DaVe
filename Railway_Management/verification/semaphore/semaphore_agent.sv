`ifndef __semaphore_agent
`define __semaphore_agent

//include the dependencies used by the agent
// typedef class semaphore_agent_monitor;
`include "semaphore_transaction.sv"
`include "semaphore_coverage.sv"
`include "semaphore_agent_driver.sv"
`include "semaphore_agent_monitor.sv"

class semaphore_agent extends uvm_agent;
  
  //the agent is added to the database of this project;
  `uvm_component_utils (semaphore_agent)
  
  //instantiate the agent's base components: the driver, monitor, and sequencer;
  semaphore_agent_driver semaphore_agent_driver_inst;
  semaphore_agent_monitor  semaphore_agent_monitor_inst;
  uvm_sequencer #(semaphore_transaction) semaphonre_agent_sequencer_inst;
  
  //declare the communication port between the agent and the scoreboard/reference environment;
  uvm_analysis_port #(semaphore_transaction) semaphore_agent_monitor_port;
  
  //declare a field that specifies whether the agent is active or passive;
  local int is_active = 0;
  
  //declare the class constructor;
  function new (string name = "semaphore_agent", uvm_component parent = null);
    super.new (name, parent);
    semaphore_agent_monitor_port = new("semaphore_agent_monitor_port", this);
  endfunction 
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    semaphore_agent_monitor_inst = semaphore_agent_monitor::type_id::create ("semaphore_agent_monitor_inst", this);
    if (is_active==1) begin
      semaphonre_agent_sequencer_inst = uvm_sequencer#(semaphore_transaction)::type_id::create ("semaphonre_agent_sequencer_inst", this);
      semaphore_agent_driver_inst = semaphore_agent_driver::type_id::create ("semaphore_agent_driver_inst", this);
    end
  endfunction
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    semaphore_agent_monitor_port = semaphore_agent_monitor_inst.semaphore_monitor_port;
    if (is_active==1)begin
      semaphore_agent_driver_inst.seq_item_port.connect (semaphonre_agent_sequencer_inst.seq_item_export);
    end
    
  endfunction
  
endclass

`endif
`ifndef __sensor_agent
`define __sensor_agent

//include the dependencies used by the agent
typedef class sensor_agent_monitor;
`include "sensor_transaction.sv"
`include "sensor_coverage.sv"
`include "sensor_agent_driver.sv"
`include "sensor_agent_monitor.sv"

class sensor_agent extends uvm_agent;
  
  //the agent is added to the database of this project;
  `uvm_component_utils (sensor_agent)
  
  //instantiate the agent's base components: the driver, monitor, and sequencer;
  sensor_agent_driver sensor_agent_driver_inst;
  sensor_agent_monitor sensor_agent_monitor_inst;
  uvm_sequencer #(sensor_transaction) sensor_agent_sequencer_inst;
  
  //declare the communication port between the agent and the scoreboard/reference environment;
  uvm_analysis_port #(sensor_transaction) sensor_agent_monitor_port;
  
  //declare a field that specifies whether the agent is active or passive;
  local int is_active = 1;
  
  //declare the class constructor;
  function new (string name = "sensor_agent", uvm_component parent = null);
    super.new (name, parent);
    sensor_agent_monitor_port = new("sensor_agent_monitor_port", this);
  endfunction 
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    sensor_agent_monitor_inst = sensor_agent_monitor::type_id::create ("sensor_agent_monitor_inst", this);
    if (is_active==1) begin
      sensor_agent_sequencer_inst = uvm_sequencer#(sensor_transaction)::type_id::create ("sensor_agent_sequencer_inst", this);
      sensor_agent_driver_inst = sensor_agent_driver::type_id::create ("sensor_agent_driver_inst", this);
    end
  endfunction
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    sensor_agent_monitor_port = sensor_agent_monitor_inst.sensor_monitor_port;
    if (is_active==1)begin
      sensor_agent_driver_inst.seq_item_port.connect (sensor_agent_sequencer_inst.seq_item_export);
    end
  endfunction
  
endclass : sensor_agent

`endif
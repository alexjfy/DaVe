`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __apb_agent
`define __apb_agent

// Include agent dependencies
typedef class monitor_apb; // Forward type definition used to solve cross dependency between monitor and coverage class
`include "apb_transaction.sv"
`include "coverage_apb.sv"
`include "driver_agent_apb.sv"
`include "monitor_apb.sv"


class agent_apb extends uvm_agent;

  `uvm_component_utils (agent_apb) // Register the agent in the UVM factory database


  // Instantiate the basic agent components: driver, monitor and sequencer; the driver and monitor are custom-built, while the sequencer is taken directly from the UVM library
  driver_agent_apb driver_agent_apb_inst0;

  monitor_apb  monitor_apb_inst0;

  uvm_sequencer #(apb_transaction) sequencer_agent_apb_inst0;


  // Declare the agent's communication port with the scoreboard/reference model; through this port the agent sends monitored data for verification; note that between monitor and agent (inside the agent) communication is done at the transaction level
  uvm_analysis_port #(apb_transaction) from_apb_monitor;


  // Declare a field indicating whether the agent is active or passive; an active agent additionally contains a driver and sequencer compared to a passive agent
  local int is_active = 1;  // 0 = passive agent; 1 = active agent


  // Class constructor; this is standard code for all components
  function new (string name = "agent_apb", uvm_component parent = null);
      super.new (name, parent);
    from_apb_monitor = new("from_apb_monitor", this);
  endfunction


  // Running a verification environment consists of multiple phases; in the "build" phase, the agent is assembled, taking into account whether it is active or passive
  virtual function void build_phase (uvm_phase phase);

    // Call build_phase from the parent class (uvm_agent)
    super.build_phase(phase);

    // Both active and passive agents need a monitor
    monitor_apb_inst0 = monitor_apb::type_id::create ("monitor_apb_inst0", this);
    // If the agent is active, add both the sequencer (component that brings data into the agent) and the driver (component that takes data from the sequencer and transmits it to the DUT adapting to its communication protocol)
    if (is_active==1) begin
      sequencer_agent_apb_inst0 = uvm_sequencer#(apb_transaction)::type_id::create ("sequencer_agent_apb_inst0", this);
      driver_agent_apb_inst0 = driver_agent_apb::type_id::create ("driver_agent_apb_inst0", this);
    end

  endfunction


  // Running a verification environment consists of multiple phases; in the "connect" phase, connections between components are established; for the agent, connections between sub-components are made
  virtual function void connect_phase (uvm_phase phase);

    // Call connect_phase from the parent class (uvm_agent)
    super.connect_phase(phase);

    // Connect the agent's port to the monitor's communication port (the monitor can only send data externally through the agent it belongs to)
    from_apb_monitor = monitor_apb_inst0.apb_monitor_port;

    // The driver receives data from the sequencer to transmit to the DUT; if the agent is active, the connection between sequencer and driver must also be established
    if (is_active==1)begin
      driver_agent_apb_inst0.seq_item_port.connect (sequencer_agent_apb_inst0.seq_item_export);
    end

  endfunction

endclass

`endif

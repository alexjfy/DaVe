`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __verification_environment
`define __verification_environment

typedef scoreboard; // Forward type definition to solve cross dependency between scoreboard and coverage class
`include "agent_apb.sv"
`include "agent_spi.sv"
`include "scoreboard.sv"

class verification_env extends uvm_env;

  // Register verification environment in UVM factory
  `uvm_component_utils(verification_env)

  // Interfaces from which data will be collected
  virtual apb_interface_dut apb_monitor_intf;
  virtual spi_interface_dut spi_monitor_intf;

  // Declare agents
  agent_apb apb_agent_inst; // Active agent that provides stimuli and monitors the input interface
  agent_spi spi_agent_inst; // Passive agent that monitors the SPI interface

  // Declare scoreboard components
  scoreboard io_scoreboard;

  // Class constructor
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Create verification environment components
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    apb_agent_inst = agent_apb::type_id::create("apb_agent_inst", this);
    spi_agent_inst = agent_spi::type_id::create("spi_agent_inst", this);
    io_scoreboard = scoreboard::type_id::create("io_scoreboard", this);
  endfunction

  // Create connections between components
  function void connect_phase(uvm_phase phase);
    `uvm_info("VERIFICATION_ENV", "Connection phase started", UVM_NONE);
    // Retrieve interfaces from UVM database
    assert(uvm_resource_db#(virtual apb_interface_dut)::read_by_name(
      get_full_name(), "apb_interface_dut", apb_monitor_intf)) else `uvm_error("VERIFICATION_ENV", "Could not retrieve apb_interface_dut from UVM database");
    assert(uvm_resource_db#(virtual spi_interface_dut)::read_by_name(
      get_full_name(), "spi_interface_dut", spi_monitor_intf)) else `uvm_error("VERIFICATION_ENV", "Could not retrieve spi_interface_dut from UVM database");
    // Connect scoreboard to agent data ports
    apb_agent_inst.from_apb_monitor.connect(io_scoreboard.apb_data_port);
    spi_agent_inst.from_spi_monitor.connect(io_scoreboard.spi_data_port);
    `uvm_info("VERIFICATION_ENV", "Connection phase completed", UVM_HIGH);
  endfunction: connect_phase

  task run_phase(uvm_phase phase);
    `uvm_info("VERIFICATION_ENV", "Verification environment RUN PHASE started.", UVM_NONE);
    begin
    end
  endtask

endclass


`endif

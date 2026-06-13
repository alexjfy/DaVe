`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

  import apb_pkg::*;
  import i2c_pkg::*;
  import uvm_pkg::*;
  `include "scoreboard.sv"

class environment extends uvm_env;

  `uvm_component_utils(environment)

  apb_agent apb_mst_agnt;
  i2c_agent i2c_slv_agnt;
  bit [`I2C_AW-1:0] i2c_address;
  scoreboard scb;


  function new(string name = "environment", uvm_component parent);
    super.new(name, parent);
  endfunction:new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // create APB agent
    apb_mst_agnt = apb_agent::type_id::create("apb_mst_agnt", this);
    // create I2C agent
    i2c_slv_agnt = i2c_agent::type_id::create("i2c_slv_agnt", this);
    i2c_address = 7'h29;
    uvm_config_db#(uvm_bitstream_t)::set(this, "i2c_slv_agnt", "i2c_address", i2c_address);
    // create scoreboard
    scb = scoreboard::type_id::create("scb", this);
  endfunction:build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    apb_mst_agnt.apb_mon.apb_port.connect(scb.apb_port);
    i2c_slv_agnt.i2c_mon.i2c_port.connect(scb.i2c_port);
  endfunction:connect_phase

endclass:environment

`endif
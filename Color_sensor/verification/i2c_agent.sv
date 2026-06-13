`ifndef I2C_AGENT_SV
`define I2C_AGENT_SV

class i2c_agent extends uvm_agent;

  bit [`I2C_AW-1:0] i2c_address;

  `uvm_component_utils(i2c_agent)

  i2c_driver    i2c_drv ;
  i2c_monitor   i2c_mon;
  i2c_coverage  i2c_cov;

  function new(string name = "i2c_agent", uvm_component parent);
    super.new(name, parent);
  endfunction:new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(uvm_bitstream_t)::get(this,"","i2c_address", i2c_address))
	    `uvm_fatal(get_type_name(), {"Agent address must be set for: ",get_full_name(),""})
           
    i2c_mon = i2c_monitor::type_id::create("i2c_mon", this);
    i2c_drv = i2c_driver::type_id::create("i2c_drv", this);
    i2c_cov = i2c_coverage::type_id::create("i2c_coverage", this);
  endfunction:build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    i2c_drv.address = i2c_address;
    i2c_mon.i2c_port.connect(i2c_cov.analysis_export);
  endfunction:connect_phase

endclass:i2c_agent

`endif
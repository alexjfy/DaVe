`ifndef I2C_PKG_SV
`define I2C_PKG_SV

package i2c_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  `include "i2c_defines.sv"
  `include "i2c_types.sv"
  `include "i2c_trans.sv"
  `include "i2c_driver.sv"
  `include "i2c_monitor.sv"
  `include "i2c_coverage.sv"
  `include "i2c_agent.sv"

  
endpackage:i2c_pkg

`endif
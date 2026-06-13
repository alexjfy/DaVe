// Module name: reset_pkg
// HDL        : System Verilog
// Description: Package collecting the reset UVC (item, driver, monitor,
//              sequencer, agent, sequence and coverage).
package reset_pkg;

  import uvm_pkg::*;

  `include "uvm_macros.svh"
  `include "reset_item.svh"
  `include "reset_driver.svh"
  `include "reset_monitor.svh"
  `include "reset_sequencer.svh"
  `include "reset_agent.svh"
  `include "reset_sequence.svh"
  `include "reset_coverage.svh"
    
endpackage
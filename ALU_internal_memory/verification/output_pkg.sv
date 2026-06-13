// Module name: output_pkg
// HDL        : System Verilog
// Description: Package collecting the passive output UVC (item, monitor,
//              agent and coverage) used to observe the ALU result bus.
package output_pkg;

  import uvm_pkg::*;

  `include "uvm_macros.svh"
  `include "output_item.svh"
  `include "output_monitor.svh"
  `include "output_agent.svh"
  `include "output_coverage.svh"

endpackage
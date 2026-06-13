// Module name: apb_pkg
// HDL        : UVM
// Description: Package collecting all the components of the APB UVC
//              (item, driver, monitor, sequencer, agent, sequences, coverage).
package apb_pkg;

  import uvm_pkg::*;

  `include "uvm_macros.svh"
  `include "apb_item.svh"
  `include "apb_driver.svh"
  `include "apb_monitor.svh"
  `include "apb_sequencer.svh"
  `include "apb_agent.svh"
  `include "apb_sequence.svh"
  `include "apb_coverage.svh"
    
endpackage
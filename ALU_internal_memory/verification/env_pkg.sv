// Module name: env_pkg
// HDL        : UVM
// Description: Package for the environment and scoreboard
package env_pkg;

  import uvm_pkg::*;
  import apb_pkg::*;
  import reset_pkg::*;
  import output_pkg::*;
  
  `include "uvm_macros.svh"
  `include "scoreboard.svh"
  `include "environment.svh"
  `include "virtual_sequencer.svh"
    
endpackage
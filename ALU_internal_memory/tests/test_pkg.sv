// Module name: test_pkg
// HDL        : UVM
// Description: Package holding the test library. Each test extends test_lib,
//              builds the environment and starts one or more APB and reset
//              sequences.
package test_pkg;

  import uvm_pkg::*;
  import apb_pkg::*;
  import reset_pkg::*;
  import output_pkg::*;
  import env_pkg::*;

  `include "uvm_macros.svh"
  `include "test_lib.svh"
   
endpackage
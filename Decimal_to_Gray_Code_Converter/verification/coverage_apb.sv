`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __apb_coverage_collector
`define __apb_coverage_collector

class coverage_apb extends uvm_component;

  // Register component in UVM factory
  `uvm_component_utils(coverage_apb)

  // Pointer to the monitor that provides data for coverage measurements
  monitor_apb p_monitor;

  covergroup stari_apb_cg;
    // Bins reflect actual addresses from documentation
    addr_cp: coverpoint p_monitor.captured_apb_tx.addr {
      bins operand_reg  = {0};   // OPERAND register (address 0x0)
      bins result_reg   = {2};   // RESULT register  (address 0x2)
      bins control_reg  = {4};   // CONTROL register (address 0x4)
      bins invalid_addresses = default;  // Any other address (invalid)
    }

    delay_cp: coverpoint p_monitor.captured_apb_tx.delay {
      bins minimal_delay = {[0:3]};
      bins small_delay   = {[4:8]};
      bins large_delay   = {[9:15]};
      bins other_delays  = {[16:$]};
    }

    perror_cp: coverpoint p_monitor.captured_apb_tx.err {
      bins no_error = {0};
      bins error    = {1};
    }

    pwrite_cp: coverpoint p_monitor.captured_apb_tx.write;

    data_cp: coverpoint p_monitor.captured_apb_tx.data {
      bins zero      = {0};
      bins low_range = {[1:84]};
      bins mid_range = {[85:169]};
      bins hi_range  = {[170:254]};
      bins maximum   = {255};
    }

    // Cross coverage: address x direction (write/read)
    cross_addr_cp_pwrite_cp: cross addr_cp, pwrite_cp;

  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    $cast(p_monitor, parent);
    stari_apb_cg = new();
  endfunction

endclass


`endif

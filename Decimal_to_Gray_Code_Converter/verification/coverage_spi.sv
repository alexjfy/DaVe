`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __spi_coverage_collector
`define __spi_coverage_collector

// This class is used to measure how many input combinations have been sent to the DUT
class coverage_spi extends uvm_component;

  // Register component in UVM factory
  `uvm_component_utils(coverage_spi)

  // Pointer to the monitor that provides data for coverage measurements
  monitor_spi p_monitor;

  covergroup stari_spi_cg;
    option.per_instance = 1;
    coverpoint p_monitor.captured_spi_state.data{
        bins min_data       = {0};
        bins random_data    = {[1:154]};
        bins random_data_1  = {[155:254]};
        bins max_data       = {255};
    }
  endgroup

  // Create the coverage group; WITHOUT this function, the covergroup can never sample data
  function new(string name, uvm_component parent);
    super.new(name, parent);
    $cast(p_monitor, parent);
    stari_spi_cg = new();
  endfunction

endclass


`endif

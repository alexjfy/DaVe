`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __spi_driver
`define __spi_driver

// The driver takes transaction-type data and sends it to the DUT according to the interface communication protocol
class driver_agent_spi extends uvm_driver #(spi_transaction);

  // Register driver in UVM factory
  `uvm_component_utils (driver_agent_spi)

  // Interface on which the driver will send data
  virtual spi_interface_dut spi_driver_intf;
  int i;

  // Class constructor
  function new(string name = "driver_agent_spi", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual spi_interface_dut)::get(this, "", "spi_interface_dut", spi_driver_intf))begin
      `uvm_fatal("DRIVER_AGENT_spi", "Could not access spi_interface_dut")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
    @(posedge spi_driver_intf.sclk);
      wait(spi_driver_intf.cs == 0);

      for(i=0;i<=7;i++)begin
      if (i<7) spi_driver_intf.miso <= 0;
      else spi_driver_intf.miso <= 1;
      @(posedge spi_driver_intf.sclk);
      end
      spi_driver_intf.miso <= 0;
      @(posedge spi_driver_intf.sclk);
    end
    `ifdef DEBUG
    $display("DRIVER_AGENT_spi, after transmission; [T=%0t]", $realtime);
    `endif;
  endtask

endclass
`endif

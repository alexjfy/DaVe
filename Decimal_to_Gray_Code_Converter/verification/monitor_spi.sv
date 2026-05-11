`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __spi_monitor
`define __spi_monitor

class monitor_spi extends uvm_monitor;

  // Register monitor in UVM factory
  `uvm_component_utils (monitor_spi)

  // Coverage collector that records signal values read by the monitor
  coverage_spi spi_coverage_inst;

  // Port through which the monitor sends captured transactions externally via the agent
  uvm_analysis_port #(spi_transaction) spi_monitor_port;

  // Interface from which the monitor collects data
  virtual spi_interface_dut spi_monitor_intf;

  spi_transaction captured_spi_state, spi_tx_copy;

  int counter_bit_pos = 7;

  // Class constructor
  function new(string name = "monitor_spi", uvm_component parent = null);
    super.new(name, parent);

    // Create the port through which the monitor sends data externally via the agent
    spi_monitor_port = new("spi_monitor_port", this);

    // Create the coverage collector (its constructor is called upon creation)
    spi_coverage_inst = coverage_spi::type_id::create ("spi_coverage_inst", this);

    // Create the transaction object that will hold data collected from the interface
    captured_spi_state = spi_transaction::type_id::create("captured_spi_state");

    spi_tx_copy = spi_transaction::type_id::create("spi_tx_copy");
  endfunction


  // Retrieve from UVM database the interface the monitor connects to
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual spi_interface_dut)::get(this, "", "spi_interface_dut", spi_monitor_intf))
        `uvm_fatal("MONITOR_spi", "Could not access monitor interface")
  endfunction


  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);

    // In UVM "connect" phase, link the coverage collector's monitor pointer to this monitor
    spi_coverage_inst.p_monitor = this;

  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    forever begin
       // 1. Wait for transaction to start (CS goes low)
       @(negedge spi_monitor_intf.cs);
       `uvm_info("MONITOR_spi", "SPI transaction detected (CS=0)", UVM_NONE)

       // 2. Sample 8 bits
       // DUT puts data on MOSI at posedge sclk.
       // We sample on NEGEDGE sclk when data is stable (set at previous posedge).
       for(counter_bit_pos = 7; counter_bit_pos >= 0; counter_bit_pos--) begin

         // 3. Wait for falling edge of sclk (data is stable from posedge)
         @(negedge spi_monitor_intf.sclk);

         // 4. Sample data
         captured_spi_state.data[counter_bit_pos] = spi_monitor_intf.mosi;
         `uvm_info("MONITOR_spi", $sformatf("Sampled bit[%0d] = %b", counter_bit_pos, spi_monitor_intf.mosi), UVM_NONE)

       end // END OF FOR LOOP

       // 5. Send the transaction ONLY ONCE, after the loop has finished
       spi_tx_copy = captured_spi_state.copy();

       spi_monitor_port.write(spi_tx_copy);
       `uvm_info("MONITOR_spi", $sformatf("Transaction received with info:"), UVM_NONE)
       spi_tx_copy.display_transaction_info();

       spi_coverage_inst.stari_spi_cg.sample();

       // 6. Wait for transaction to end (CS returns to 1)
       @(posedge spi_monitor_intf.cs);
       `uvm_info("MONITOR_spi", "SPI transaction ended (CS=1)", UVM_NONE)

     end//forever begin
  endtask

endclass: monitor_spi

`endif

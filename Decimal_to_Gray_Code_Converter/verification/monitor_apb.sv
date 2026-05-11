// APB Monitor - captures transactions from the APB interface
`ifndef __monitor_apb
`define __monitor_apb
`include "apb_transaction.sv"



class monitor_apb extends uvm_monitor;

  // Register monitor in UVM factory
  `uvm_component_utils (monitor_apb)

  // Coverage collector that records signal values read by the monitor
  coverage_apb apb_coverage_inst;

  // Port through which the monitor sends captured transactions to the outside (accessed by scoreboard) via the agent
  uvm_analysis_port #(apb_transaction) apb_monitor_port;

  // Interface from which the monitor collects data
  virtual apb_interface_dut monitor_intf;

  apb_transaction captured_apb_tx, apb_tx_copy;

  int delay;

  // Class constructor
  function new(string name = "monitor_apb", uvm_component parent = null);
    super.new(name, parent);

    // Create the port through which the monitor sends data externally via the agent
    apb_monitor_port = new("apb_monitor_port", this);

    // Create the coverage collector (its constructor is called upon creation)
    apb_coverage_inst = coverage_apb::type_id::create ("apb_coverage_inst", this);

    // Create the transaction object that will hold data collected from the interface
    captured_apb_tx = apb_transaction::type_id::create("captured_apb_tx");

    apb_tx_copy = apb_transaction::type_id::create("apb_tx_copy");
  endfunction


  // Retrieve from UVM database the interface the monitor connects to
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

      if (!uvm_config_db#(virtual apb_interface_dut)::get(this, "", "apb_interface_dut", monitor_intf))
        `uvm_fatal("monitor_apb", "Could not access monitor interface")
  endfunction


  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);

    // In UVM "connect" phase, link the coverage collector's monitor pointer to this monitor
    apb_coverage_inst.p_monitor = this;

  endfunction

  // The monitor samples on NEGEDGE pclk to avoid race-condition with the driver
  // (driver sets signals on posedge => on negedge values are stable)
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    forever begin
      // 1. Count idle cycles (psel=0) on negedge pclk
      delay = 0;
      @(negedge monitor_intf.pclk);
      while (monitor_intf.psel !== 1'b1) begin
        delay++;
        @(negedge monitor_intf.pclk);
      end
      // Now psel=1 (SETUP phase seen on negedge = stable)

      // 2. Wait for complete ACCESS phase: penable=1 and pready=1 on negedge
      @(negedge monitor_intf.pclk iff (monitor_intf.penable == 1 && monitor_intf.pready == 1));

      // 3. Capture data from interface (on negedge, values are stable)
      captured_apb_tx.addr = monitor_intf.paddr;
      captured_apb_tx.write = monitor_intf.pwrite;

      if (monitor_intf.pwrite == 1)
        captured_apb_tx.data = monitor_intf.pwdata;
      else
        captured_apb_tx.data = monitor_intf.prdata;

      captured_apb_tx.err = monitor_intf.pslverr;
      captured_apb_tx.delay = delay;
      $display("[MONITOR-APB-DBG] addr=%0d write=%0b data=0x%0h err=%0b delay=%0d at T=%0t",
               captured_apb_tx.addr, captured_apb_tx.write,
               captured_apb_tx.data, captured_apb_tx.err,
               captured_apb_tx.delay, $time);

      apb_tx_copy = captured_apb_tx.copy();

      // 4. Send the transaction on the monitor port
      apb_monitor_port.write(apb_tx_copy);

      // 5. Sample coverage
      apb_coverage_inst.stari_apb_cg.sample();

    end//forever begin
  endtask

endclass: monitor_apb

`endif

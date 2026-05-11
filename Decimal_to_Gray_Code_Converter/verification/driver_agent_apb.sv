`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __apb_driver
`define __apb_driver

// The driver takes transaction-type data and sends it to the DUT according to the interface communication protocol
class driver_agent_apb extends uvm_driver #(apb_transaction);

  // Register driver in UVM factory
  `uvm_component_utils (driver_agent_apb)

  // Interface on which the driver will send data
  virtual apb_interface_dut apb_driver_intf;

  // Class constructor
  function new(string name = "driver_agent_apb", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_interface_dut)::get(this, "", "apb_interface_dut", apb_driver_intf))begin
      `uvm_fatal("DRIVER_AGENT_apb", "Could not access apb_interface_dut")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      `uvm_info("DRIVER_AGENT_apb", $sformatf("Waiting for a transaction from sequencer"), UVM_LOW)
      seq_item_port.get_next_item(req);
      `uvm_info("DRIVER_AGENT_apb", $sformatf("Received transaction from sequencer: addr=%0h write=%0b data=%0h",
                req.addr, req.write, req.data), UVM_LOW)
      send_transaction(req);
      `uvm_info("DRIVER_AGENT_apb", $sformatf("Transaction has been sent on interface"), UVM_LOW)
      seq_item_port.item_done();
    end
  endtask

  // Walk the APB transaction through its 3 phases: SETUP -> ACCESS -> IDLE.
  // tx_info.delay gives the number of idle clks we wait before driving setup.
  task send_transaction(apb_transaction tx_info);
    $timeformat(-9, 2, " ns", 20);

    //idle gap before starting the transaction
    repeat(tx_info.delay) @(posedge apb_driver_intf.pclk);

    // SETUP phase (T1): psel=1, penable=0, drive addr + (optionally) data
    apb_driver_intf.psel    = 'b1;
    apb_driver_intf.penable = 'b0;
    apb_driver_intf.paddr   = tx_info.addr;
    apb_driver_intf.pwrite  = tx_info.write;

    if (apb_driver_intf.pwrite)
      apb_driver_intf.pwdata = tx_info.data;

    $display("[DRIVER-APB] INFO: SETUP phase - addr=%0h write=%0b data=%0h at T=%0t",
             tx_info.addr, tx_info.write,
             tx_info.data, $time);

    // ACCESS phase (T2): raise penable
    @(posedge apb_driver_intf.pclk);
    apb_driver_intf.penable = 'b1;

    // per APB spec the master holds penable=1 until the slave asserts pready
    @(posedge apb_driver_intf.pclk iff apb_driver_intf.pready == 1);

    $display("[DRIVER-APB] INFO: ACCESS phase complete - pready received at T=%0t", $time);

    // IDLE phase (T3): release the bus
    apb_driver_intf.psel    = 'b0;
    apb_driver_intf.penable = 'b0;
    apb_driver_intf.pwrite  = 'bx;
    apb_driver_intf.pwdata  = 8'bx;
    // prdata belongs to the DUT, not driven here

  endtask

endclass
`endif

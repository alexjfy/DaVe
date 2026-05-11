`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __spi_transaction
`define __spi_transaction

// A transaction represents all data transmitted at a given time on an interface
class spi_transaction extends uvm_sequence_item;

  // Register component in UVM factory
  `uvm_object_utils(spi_transaction)

  bit[7:0] data;

  // Class constructor
  function new(string name = "spi_tx_item");
    super.new(name);
    data = 0;
  endfunction

  // Display transaction information
  function void display_transaction_info();
    $display("Data value: %0h", data);
  endfunction

  function spi_transaction copy();
    copy = new();
    copy.data = this.data;
    return copy;
  endfunction

endclass
`endif

`ifndef __apb_transaction
`define __apb_transaction

// A transaction represents all data transmitted at a given time on an interface
class apb_transaction extends uvm_sequence_item;

  // Register component in UVM factory
  `uvm_object_utils(apb_transaction)

  rand bit[3-1:0] addr;
  rand bit write; // 1: write transaction; 0: read transaction
  rand bit [8-1:0] data;
  rand bit err;
  rand int delay;

  constraint delay_c {soft delay inside {[1:15]};}

  // Class constructor
  function new(string name = "apb_tx_item");
    super.new(name);
    data = 0;
    addr = 0;
    write = 0;
    addr = 0;
    err = 0;
    delay = 3;
  endfunction

  // Display transaction information
  function void display_transaction_info();
    $display("\t APB: addr  = %0h\t write = %0h\t data = %0h \t err = %0h \t delay = %0d", addr, write, data, err, delay);
  endfunction

  function apb_transaction copy();
    apb_transaction transaction;
    transaction = new();
    transaction.addr  = this.addr;
    transaction.write = this.write;
    transaction.data = this.data;
    transaction.delay = this.delay;
    transaction.err = this.err;
    return transaction;
  endfunction

endclass
`endif

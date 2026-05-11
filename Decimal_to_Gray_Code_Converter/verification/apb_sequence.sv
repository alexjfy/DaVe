`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __input_apb_sequence
`define __input_apb_sequence

class apb_seq_write_addr4 extends uvm_sequence #(apb_transaction);

  `uvm_object_utils(apb_seq_write_addr4)

  function new(string name="apb_seq_write_addr4");
    super.new(name);
  endfunction

  rand int num_transactions;

  constraint sequence_size_c{
    soft num_transactions == 1;
  }
  function void post_randomize();
    $display("apb_seq_write_addr4: Transaction sequence size=%0d", num_transactions);
  endfunction

  virtual task body();
    `uvm_info("apb_seq_write_addr4", $sformatf("Sequence started with %-2d elements", num_transactions), UVM_NONE)

    for (int i=0; i< num_transactions; i++) begin
      req = apb_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {addr==4;
                                     write ==1;
                                     delay inside {[0:3]};
                                     data == 'b00000001;});
      `ifdef DEBUG
      `uvm_info("apb_seq_write_addr4", $sformatf("At time %0t generated element %0d", $time, i), UVM_LOW)
        req.display_transaction_info();
      `endif;
      finish_item(req);
    end
    `uvm_info("apb_seq_write_addr4", $sformatf("All %0d transactions generated", num_transactions), UVM_LOW)
  endtask
endclass


class apb_seq_write_addr0_fixed_data extends uvm_sequence #(apb_transaction);

  `uvm_object_utils(apb_seq_write_addr0_fixed_data)
  rand bit[7:0] data_transmitted;
  function new(string name="apb_seq_write_addr0_fixed_data");
    super.new(name);
  endfunction

  rand int num_transactions;

  constraint sequence_size_c{
    soft num_transactions == 1;
  }
  function void post_randomize();
    $display("apb_seq_write_addr0_fixed_data: Transaction sequence size=%0d", num_transactions);
  endfunction

  virtual task body();
    `uvm_info("apb_seq_write_addr0_fixed_data", $sformatf("Sequence started with %-2d elements", num_transactions), UVM_NONE)

    for (int i=0; i< num_transactions; i++) begin
      req = apb_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {addr==0;
                                     write ==1;
                                     delay inside {[0:3]};
                                     data == data_transmitted;});
      `ifdef DEBUG
      `uvm_info("apb_seq_write_addr0_fixed_data", $sformatf("At time %0t generated element %0d", $time, i), UVM_LOW)
        req.display_transaction_info();
      `endif;
      finish_item(req);
    end
    `uvm_info("apb_seq_write_addr0_fixed_data", $sformatf("All %0d transactions generated", num_transactions), UVM_LOW)
  endtask
endclass


class apb_seq_write_addr0 extends uvm_sequence #(apb_transaction);

  `uvm_object_utils(apb_seq_write_addr0)

  function new(string name="apb_seq_write_addr0");
    super.new(name);
  endfunction

  rand int num_transactions;

  constraint sequence_size_c{
    soft num_transactions == 1;
  }
  function void post_randomize();
    $display("apb_seq_write_addr0: Transaction sequence size=%0d", num_transactions);
  endfunction

  virtual task body();
    `uvm_info("apb_seq_write_addr0", $sformatf("Sequence started with %-2d elements", num_transactions), UVM_NONE)

    for (int i=0; i< num_transactions; i++) begin
      req = apb_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {addr==0;
                                     write ==1;
                                     delay inside {[0:3]};
                                     });
      `ifdef DEBUG
      `uvm_info("apb_seq_write_addr0", $sformatf("At time %0t generated element %0d", $time, i), UVM_LOW)
        req.display_transaction_info();
      `endif;
      finish_item(req);
    end
    `uvm_info("apb_seq_write_addr0", $sformatf("All %0d transactions generated", num_transactions), UVM_LOW)
  endtask
endclass

class apb_sequence extends uvm_sequence #(apb_transaction);

  `uvm_object_utils(apb_sequence)

  rand int num_transactions;

  constraint sequence_size_c{
    soft num_transactions inside {[10:10+5]};
  }

  function new(string name="apb_sequence");
    super.new(name);
  endfunction

  function void post_randomize();
    $display("APB_SEQUENCE: Transaction sequence size=%0d", num_transactions);
  endfunction

  virtual task body();
    `uvm_info("APB_SEQUENCE", $sformatf("Sequence started with %-2d elements", num_transactions), UVM_NONE)

    for (int i=0; i< num_transactions; i++) begin
      req = apb_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {addr inside {[0:4]};
                                     write inside {[0:1]};
                                     delay inside {[0:3]};});
      `ifdef DEBUG
      `uvm_info("APB_SEQUENCE", $sformatf("At time %0t generated element %0d", $time, i), UVM_LOW)
        req.display_transaction_info();
      `endif;
      finish_item(req);
    end
    `uvm_info("APB_SEQUENCE", $sformatf("All %0d transactions generated", num_transactions), UVM_LOW)
  endtask
endclass

// Read sequence: issues a read from `read_addr`, used whenever a test
// needs to pull back a register value.
class apb_seq_read extends uvm_sequence #(apb_transaction);

  `uvm_object_utils(apb_seq_read)

  rand bit [2:0] read_addr;
  rand int num_transactions;

  constraint sequence_size_c {
    soft num_transactions == 1;
  }

  function new(string name="apb_seq_read");
    super.new(name);
  endfunction

  function void post_randomize();
    $display("apb_seq_read: addr=%0d, num_transactions=%0d", read_addr, num_transactions);
  endfunction

  virtual task body();
    `uvm_info("apb_seq_read", $sformatf("Read from addr=%0d, %0d transactions",
              read_addr, num_transactions), UVM_NONE)

    for (int i = 0; i < num_transactions; i++) begin
      req = apb_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {
        addr  == read_addr;
        write == 0;           // read
        delay inside {[0:3]};
      });
      finish_item(req);
    end
    `uvm_info("apb_seq_read", $sformatf("All %0d read transactions generated", num_transactions), UVM_LOW)
  endtask
endclass

// Generic sequence: addr, write and data are all driven from outside the
// sequence. Handy for PSLVERR scenarios (writes to invalid addresses, or
// writes to read-only registers), where we need full control of the txn.
class apb_seq_generic extends uvm_sequence #(apb_transaction);

  `uvm_object_utils(apb_seq_generic)

  rand bit [2:0] target_addr;
  rand bit       target_write;
  rand bit [7:0] target_data;
  rand int       target_delay;
  rand int num_transactions;

  constraint sequence_size_c {
    soft num_transactions == 1;
  }
  constraint delay_c {
    soft target_delay inside {[0:3]};
  }

  function new(string name="apb_seq_generic");
    super.new(name);
  endfunction

  function void post_randomize();
    $display("apb_seq_generic: addr=%0d, write=%0b, data=0x%0h, delay=%0d, num=%0d",
             target_addr, target_write, target_data, target_delay, num_transactions);
  endfunction

  virtual task body();
    `uvm_info("apb_seq_generic", $sformatf("Transaction: addr=%0d, write=%0b, data=0x%0h, delay=%0d",
              target_addr, target_write, target_data, target_delay), UVM_NONE)

    for (int i = 0; i < num_transactions; i++) begin
      req = apb_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {
        addr  == target_addr;
        write == target_write;
        data  == target_data;
        delay == target_delay;
      });
      finish_item(req);
    end
    `uvm_info("apb_seq_generic", $sformatf("All %0d generic transactions generated", num_transactions), UVM_LOW)
  endtask
endclass

`endif

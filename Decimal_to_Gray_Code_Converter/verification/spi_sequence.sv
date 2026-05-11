`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __spi_sequence
`define __spi_sequence

// SPI Sequence
// The SPI agent is passive (monitor only), so this sequence is for reference
// and is not actively used in tests (no active SPI sequencer)
class spi_sequence extends uvm_sequence #(spi_transaction);

  `uvm_object_utils(spi_sequence)

  rand int num_transactions;

  constraint sequence_size_c{
    soft num_transactions inside {[10:15]};
  }

  function new(string name="spi_sequence");
    super.new(name);
  endfunction

  function void post_randomize();
    $display("SPI_SEQUENCE: Transaction sequence size=%0d", num_transactions);
  endfunction

  virtual task body();
    `uvm_info("SPI_SEQUENCE", $sformatf("Sequence started with %-2d elements", num_transactions), UVM_NONE)

    for (int i = 0; i < num_transactions; i++) begin
      req = spi_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize());
      `ifdef DEBUG
        `uvm_info("SPI_SEQUENCE", $sformatf("At time %0t generated element %0d", $time, i), UVM_LOW)
        req.display_transaction_info();
      `endif
      finish_item(req);
    end
    `uvm_info("SPI_SEQUENCE", $sformatf("All %0d transactions generated", num_transactions), UVM_LOW)
  endtask
endclass
`endif

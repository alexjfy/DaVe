// Coverage class for APB transactions. By sampling transactions here we can measure
// which address/data/direction combinations have been exercised during simulation.
`include "defines.sv"

class apb_coverage;

  apb_transaction trans_covered;

  // A single covergroup captures address, transaction type, data range, and their cross.
  // option.per_instance=1 keeps a separate coverage bucket for each object instance,
  // which is useful when multiple drivers share the same class.
  covergroup transaction_cg;
    option.per_instance = 1;

    // Covers both write (pwrite=1) and read (pwrite=0) transaction types.
    pwrite_enable_cp: coverpoint trans_covered.pwrite;

    // Only 3 valid DUT register addresses exist: 0=temp_set, 1=operation_mod, 2=timer.
    // All other addresses are declared illegal so the tool flags them as errors.
    address_cp: coverpoint trans_covered.paddr {
      bins temp_set_reg      = {0};
      bins operation_mod_reg = {1};
      bins timer_reg         = {2};
      illegal_bins invalid   = default;
    }

    // Data bus values split into 4 equal ranges plus the two boundary values.
    data_cp: coverpoint trans_covered.data {
      bins range[4]       = {[0:$]};
      bins lowest_value   = {0};
      bins highest_value  = {2**`DATA_WIDTH-1};
    }

    // Cross coverage: every combination of address and read/write direction.
    pwrite_enable_address_cx: cross pwrite_enable_cp, address_cp;
  endgroup

  // The covergroup must be instantiated in the constructor; declaration alone is not enough.
  function new();
    transaction_cg = new();
  endfunction

  // Called by the monitor for every completed APB transaction to record coverage.
  task sample(apb_transaction trans_covered);
    this.trans_covered = trans_covered;
    transaction_cg.sample();
  endtask : sample

  // Prints per-coverpoint percentages and the overall coverage figure.
  function print_coverage();
    $display("[APB-COV] Address coverage       = %.2f%%", transaction_cg.address_cp.get_coverage());
    $display("[APB-COV] Transaction type        = %.2f%%", transaction_cg.pwrite_enable_cp.get_coverage());
    $display("[APB-COV] Data coverage           = %.2f%%", transaction_cg.data_cp.get_coverage());
    $display("[APB-COV] Cross coverage          = %.2f%%", transaction_cg.pwrite_enable_address_cx.get_coverage());
    $display("[APB-COV] Overall APB coverage    = %.2f%%", transaction_cg.get_coverage());
  endfunction

endclass : apb_coverage

// Coverage class for the LED output. Ensures that both LED states
// (on and off) are observed at the DUT output during simulation.
class led_coverage;

  led_transaction trans_covered;

  // option.per_instance=1 keeps separate buckets if multiple instances exist.
  covergroup transaction_cg;
    option.per_instance = 1;

    // Covers both led=1 (cooking done, all conditions met) and led=0 (LED off).
    led_cp: coverpoint trans_covered.led;
  endgroup

  // Covergroup must be instantiated here; declaration alone is not sufficient.
  function new();
    transaction_cg = new();
  endfunction

  // Called by the LED monitor for every sampled LED transaction.
  task sample(led_transaction trans_covered);
    this.trans_covered = trans_covered;
    transaction_cg.sample();
  endtask : sample

  // Prints LED state coverage percentages.
  function print_coverage();
    $display("[LED-COV] LED state coverage    = %.2f%%", transaction_cg.led_cp.get_coverage());
    $display("[LED-COV] Overall LED coverage  = %.2f%%", transaction_cg.get_coverage());
  endfunction

endclass : led_coverage

// Coverage class for door transactions. Ensures that both door states
// (open and closed) are exercised during simulation.
class door_coverage;

  door_transaction trans_covered;

  // option.per_instance=1 keeps separate buckets if multiple instances exist.
  covergroup transaction_cg;
    option.per_instance = 1;

    // Covers both door_closed=1 (door shut) and door_closed=0 (door open).
    door_closed_cp: coverpoint trans_covered.door_closed;
  endgroup

  // Covergroup must be instantiated here; declaration alone is not sufficient.
  function new();
    transaction_cg = new();
  endfunction

  // Called by the door monitor for every sampled door transaction.
  task sample(door_transaction trans_covered);
    this.trans_covered = trans_covered;
    transaction_cg.sample();
  endtask : sample

  // Prints door state coverage percentages.
  function print_coverage();
    $display("[DOOR-COV] Door state coverage  = %.2f%%", transaction_cg.door_closed_cp.get_coverage());
    $display("[DOOR-COV] Overall door coverage = %.2f%%", transaction_cg.get_coverage());
  endfunction

endclass : door_coverage

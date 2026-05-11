// Through coverage, we can see which situations (e.g., which types of transactions)
// were generated during simulation; this allows us to measure the verification progress
class out_coverage;

  out_transaction trans_covered;

  // To see the coverage value for each element, multiple coverage groups must be created,
  // or a custom display function must be written
  covergroup transaction_cg;
    // The line below is added because if there are multiple instances for which coverage
    // is calculated, we want to know the value for each one separately
    option.per_instance = 1;
    wipers_cp: coverpoint trans_covered.wipers;

    high_beam_cp: coverpoint trans_covered.high_beam;

    washer_cp: coverpoint trans_covered.washer;

    flash_cp: coverpoint trans_covered.flash;

    right_signal_cp: coverpoint  trans_covered.right_signal{option.weight = 0;}

    left_signal_cp:coverpoint trans_covered.left_signal{option.weight = 0;}

    hazard_cx: cross right_signal_cp, left_signal_cp;
  endgroup

  // The coverage group is created here; WITHOUT this function, the coverage group
  // would never be able to sample data because until now it was only declared, not created
  function new();
    transaction_cg = new();
  endfunction

  task sample(out_transaction trans_covered);
  	this.trans_covered = trans_covered;
  	transaction_cg.sample();
  endtask:sample

  task print_coverage();
    $display ("Wipers coverage = %.2f%%", transaction_cg.wipers_cp.get_coverage());
    $display ("High_beam coverage = %.2f%%", transaction_cg.high_beam_cp.get_coverage());
    $display ("Washer coverage = %.2f%%", transaction_cg.washer_cp.get_coverage());
    $display ("Flash coverage = %.2f%%", transaction_cg.flash_cp.get_coverage());
    $display ("Hazard coverage = %.2f%%", transaction_cg.hazard_cx.get_coverage());
  endtask

endclass: out_coverage

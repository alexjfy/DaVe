// Through coverage, we can see which situations (e.g., which types of transactions)
// were generated during simulation; this allows us to measure the verification progress
class apb_coverage;

  apb_transaction trans_covered;

  // To see the coverage value for each element, multiple coverage groups must be created,
  // or a custom display function must be written
  covergroup apb_transaction_cg;
    // The line below is added because if there are multiple instances for which coverage
    // is calculated, we want to know the value for each one separately
    option.per_instance = 1;
    wr_enable_cp: coverpoint trans_covered.write_enable;
    address_cp: coverpoint trans_covered.address;
    data_cp: coverpoint trans_covered.data {
      bins range[4] = {[0:255]};
      bins lowest_value = {0};
      bins highest_value = {255};
    }
    address__wr_enable_cx : cross address_cp, wr_enable_cp;
  endgroup

  // The coverage group is created here; WITHOUT this function, the coverage group
  // would never be able to sample data because until now it was only declared, not created
  function new();
    apb_transaction_cg = new();
  endfunction

  task sample(apb_transaction trans_covered);
  	this.trans_covered = trans_covered;
  	apb_transaction_cg.sample();
  endtask:sample

  task print_coverage();
    $display ("Write_enable coverage = %.2f%%", apb_transaction_cg.wr_enable_cp.get_coverage());
    $display ("address coverage = %.2f%%", apb_transaction_cg.address_cp.get_coverage());
    $display ("data_cp coverage = %.2f%%", apb_transaction_cg.data_cp.get_coverage());
    $display ("address__wr_enable_cx coverage = %.2f%%", apb_transaction_cg.address__wr_enable_cx.get_coverage());
  endtask

endclass: apb_coverage

//Through coverage, we can see which scenarios (e.g., which transaction types) were generated during simulation; this allows us to measure verification progress
class coverageAPB;

  transactionAPB trans_covered;

  covergroup transaction_cg;
    option.per_instance = 1;

    //Read vs Write coverage
    wr_enable: coverpoint trans_covered.write {
      bins read  = {0};
      bins write = {1};
    }

    //Only valid ALU register addresses (aligned to 4 bytes)
    address: coverpoint trans_covered.addr {
      bins DATA      = {5'h00};
      bins OPS       = {5'h04};
      bins STATUS    = {5'h08};
      bins DIVIDER   = {5'h0C};
      bins CONTROL   = {5'h10};
      bins MASK      = {5'h14};
      bins CONFIG    = {5'h18};
      bins invalid[] = default;
    }

    //Write data bins — relevant value ranges for ALU operands and control fields
    write_data: coverpoint trans_covered.data {
      bins zero       = {0};
      bins low        = {[1:15]};
      bins mid        = {[16:255]};
      bins hi         = {[256:65535]};
      bins very_large = {[65536:$]};
    }

    //Cross coverage: which registers are read vs written
    addr_x_rw: cross address, wr_enable;
  endgroup

  function new();
    transaction_cg = new();
  endfunction

  task sample(transactionAPB trans_covered);
    this.trans_covered = trans_covered;
    transaction_cg.sample();
  endtask:sample

  function print_coverage();
    $display ("Address coverage = %.2f%%", transaction_cg.address.get_coverage());
    $display ("Write data coverage = %.2f%%", transaction_cg.write_data.get_coverage());
    $display ("Write_enable coverage = %.2f%%", transaction_cg.wr_enable.get_coverage());
    $display ("Addr x RW cross coverage = %.2f%%", transaction_cg.addr_x_rw.get_coverage());
    $display ("APB overall coverage = %.2f%%", transaction_cg.get_coverage());
  endfunction

endclass: coverageAPB


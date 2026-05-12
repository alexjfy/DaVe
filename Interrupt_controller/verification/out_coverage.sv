//through coverage, we can see which scenarios (e.g., which transaction types) have been generated during simulation; this allows us to measure verification progress
class out_coverage;

  out_transaction trans_covered;

  //to see the coverage value for each element, multiple coverage groups must be created, or a custom display function must be written
  covergroup out_transaction_cg;
     //the line below is added because, if there are multiple instances for which coverage is computed, we want to know the value for each one separately.
    option.per_instance = 1;
    interrupt_cov: coverpoint trans_covered.irq;

  endgroup
  //create the coverage group; NOTE! Without the function below, the coverage group will never be able to sample data because so far it was only declared, not created
  function new();
    out_transaction_cg = new();
  endfunction

  task sample(out_transaction trans_covered);
  	this.trans_covered = trans_covered;
  	out_transaction_cg.sample();
  endtask:sample

  function void print_coverage();
    $display ("interrupt_code coverage = %.2f%%",
    out_transaction_cg.interrupt_cov.get_coverage());

  endfunction

  //another way to end a class declaration is to write "endclass: class_name"; this is especially useful when declaring multiple classes in the same file; however, it is recommended that each file contains no more than one class declaration
endclass: out_coverage
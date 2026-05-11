//Through coverage, we can see which scenarios (e.g., which transaction types) were generated during simulation; this allows us to measure verification progress
class irq_coverage;
  
  IRQ_transaction trans_covered;
  
  //To see coverage values for each element, multiple covergroups must be created, or a custom display function is needed
  covergroup transaction_cg;
    //The line below is added because, with multiple instances calculating coverage, we want to know the value for each one separately
    option.per_instance = 1;
    irq_cp: coverpoint trans_covered.irq;

  endgroup
  //Create the covergroup instance; NOTE: without this constructor, the covergroup can never sample data because it was only declared, not instantiated
  function new();
    transaction_cg = new();
  endfunction
  
  task sample(IRQ_transaction trans_covered); 
  	this.trans_covered = trans_covered; 
  	transaction_cg.sample(); 
  endtask:sample   
  
  function print_coverage();
    $display ("interrupt coverage = %.2f%%", transaction_cg.irq_cp.get_coverage());
  endfunction
  
  //Another way to end a class declaration is to write "endclass: class_name"; this is especially useful when declaring multiple classes in the same file; however, it is recommended that each file contains no more than one class declaration
endclass: irq_coverage

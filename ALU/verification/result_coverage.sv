class result_coverage;
  
  result_transaction trans_covered;
  
  //To see coverage values for each element, multiple covergroups must be created, or a custom display function is needed
  covergroup transaction_cg;
    //The line below is added because, with multiple instances calculating coverage, we want to know the value for each one separately
    option.per_instance = 1;

    read_data: coverpoint trans_covered.result {
      bins zero       = {0};
      bins low        = {[1:15]};
      bins mid        = {[16:255]};
      bins hi         = {[256:65535]};
    }
    
  endgroup
  //Create the covergroup instance; NOTE: without this constructor, the covergroup can never sample data because it was only declared, not instantiated
  function new();
    transaction_cg = new();
  endfunction
  
  task sample(result_transaction trans_covered); 
  	this.trans_covered = trans_covered; 
  	transaction_cg.sample(); 
  endtask:sample   
  
  function print_coverage();
    $display ("Result coverage = %.2f%%", transaction_cg.read_data.get_coverage());
   
    $display ("Overall coverage = %.2f%%", transaction_cg.get_coverage());
  endfunction
  
  //Another way to end a class declaration is to write "endclass: class_name"; this is especially useful when declaring multiple classes in the same file; however, it is recommended that each file contains no more than one class declaration
endclass: result_coverage

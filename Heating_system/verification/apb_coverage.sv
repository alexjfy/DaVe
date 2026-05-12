//through coverage, we can see what scenarios (e.g., what transaction types) were generated during simulation; this allows us to measure verification progress
class apb_coverage;
  
  apb_transaction trans_covered;
  
  //to see coverage values for each element, multiple coverage groups must be created, or a custom display function must be written
  covergroup apb_transaction_cg;
    //added because when there are multiple instances, we want to know the coverage value for each one separately.
    option.per_instance = 1;
    pwrite_cp: coverpoint trans_covered.pwrite;
    paddr_cp: coverpoint trans_covered.paddr;
    data_cp: coverpoint trans_covered.data {
      //the line below divides the value range into 4 equal intervals
      bins range[4] = {[0:$]};
      bins lowest_value = {0};
      bins highest_value = {2**DATA_WIDTH-1};
    }
    
  endgroup
  //create the coverage group - if we skip this new(), sampling silently does nothing
  function new();
    apb_transaction_cg = new();
  endfunction
  
  task sample(apb_transaction trans_covered); 
  	this.trans_covered = trans_covered; 
  	apb_transaction_cg.sample(); 
  endtask:sample   
  
  function print_coverage();
    $display ("  paddr coverage   = %.2f%%", apb_transaction_cg.paddr_cp.get_coverage());
    $display ("  data coverage    = %.2f%%", apb_transaction_cg.data_cp.get_coverage());
    $display ("  pwrite coverage  = %.2f%%", apb_transaction_cg.pwrite_cp.get_coverage());
    $display ("  Overall APB coverage = %.2f%%", apb_transaction_cg.get_coverage());
  endfunction
  
endclass: apb_coverage


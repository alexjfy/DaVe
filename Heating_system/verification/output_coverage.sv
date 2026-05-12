//coverage class for the output side - just samples the flame signal
class output_coverage;

  output_transaction trans_covered;

  covergroup output_transaction_cg;
    option.per_instance = 1; //per-instance so we see each instance separately
    unit_on_cp: coverpoint trans_covered.unit_on;
  endgroup

  function new();
    output_transaction_cg = new();
  endfunction
  
  task sample(output_transaction trans_covered); 
  	this.trans_covered = trans_covered; 
  	output_transaction_cg.sample(); 
  endtask:sample   
  
  function print_coverage();
    $display ("  flame (unit_on) coverage = %.2f%%", output_transaction_cg.unit_on_cp.get_coverage());
    $display ("  Overall output coverage           = %.2f%%", output_transaction_cg.get_coverage());
  endfunction
  
endclass: output_coverage


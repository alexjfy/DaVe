// tracks which button combinations have been exercised during simulation;
// each coverpoint is a single bit so it just needs to see both 0 and 1
class buttons_coverage;

  buttons_transaction trans_covered;

  covergroup transaction_cg;
    option.per_instance = 1; // report per instance so multiple collectors stay independent
    button_mod_econ_cp:      coverpoint trans_covered.button_mod_econ;
    button_mod_comf_cp:      coverpoint trans_covered.button_mod_comf;
    button_mod_thermo_cp:    coverpoint trans_covered.button_mod_thermo;
    button_child_prot_cp:    coverpoint trans_covered.button_child_prot;
  endgroup
  //instantiate the covergroup (without this it won't sample anything)
  function new();
    transaction_cg = new();
  endfunction
  
  task sample(buttons_transaction trans_covered); 
  	this.trans_covered = trans_covered; 
  	transaction_cg.sample(); 
  endtask:sample   
  
  function print_coverage();
    $display ("  button_mod_econ coverage      = %.2f%%", transaction_cg.button_mod_econ_cp.get_coverage());
    $display ("  button_mod_comf coverage      = %.2f%%", transaction_cg.button_mod_comf_cp.get_coverage());
    $display ("  button_mod_thermo coverage = %.2f%%", transaction_cg.button_mod_thermo_cp.get_coverage());
    $display ("  button_child_prot coverage    = %.2f%%", transaction_cg.button_child_prot_cp.get_coverage());
    $display ("  Overall buttons coverage     = %.2f%%", transaction_cg.get_coverage());
  endfunction
  
endclass: buttons_coverage


`ifndef __rare_button_sequence
`define __rare_button_sequence

class rare_button_sequence extends uvm_sequence #(button_transaction);
  
  //add sequence to the UVM database
  `uvm_object_utils(rare_button_sequence)
  
  rand int nr_of_trans;
  
  //constrains the number of transactions
  constraint nr_of_trans_c{
    soft nr_of_trans inside {[`MIN_TRANSACTION_NR:`MIN_TRANSACTION_NR+5]};
  }
  
  function new(string name="rare_button_sequence");
    super.new(name);
  endfunction
    
  function void post_randomize();
    `uvm_info("RARE_BUTTON_SEQUENCE", $sformatf("Number of transactions=%0d", nr_of_trans), UVM_DEBUG)
  endfunction
  
  virtual task body();
    for (int i=0; i < nr_of_trans; i++) begin
      req = button_transaction::type_id::create("req");
      
      start_item(req);
      assert (req.randomize() with{enable dist { 0:= 8, 1:= 2}; });
      if(i == nr_of_trans-1) //last transaction must have enable = 1, to allow the system to work and thus to be able to send all the transactions of temperature
        req.enable = 1;
      `uvm_info("RARE_BUTTON_SEQUENCE", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    `uvm_info("RARE_BUTTON_SEQUENCE", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask

endclass : rare_button_sequence

`endif
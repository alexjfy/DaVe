`ifndef __random_sequence
`define __random_sequence

class random_sequence extends uvm_sequence #(button_transaction);
  
  //add sequence to the UVM database
  `uvm_object_utils(random_sequence)
  
  rand int nr_of_trans;
  
  //constrains the number of transactions
  constraint nr_of_trans_c{
    soft nr_of_trans inside {[`MIN_TRANSACTION_NR:`MIN_TRANSACTION_NR+5]};
  }
  
  function new(string name="random_sequence");
    super.new(name);
  endfunction
    
  function void post_randomize();
    `uvm_info("RANDOM_SEQUENCE", $sformatf("Number of transactions=%0d", nr_of_trans), UVM_DEBUG)
  endfunction
  
  virtual task body();
    for (int i=0; i< nr_of_trans; i++) begin
      req = button_transaction::type_id::create("req");
      
      start_item(req);
      assert (req.randomize());
      `uvm_info("RANDOM_SEQUENCE", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    `uvm_info("RANDOM_SEQUENCE", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask
endclass
`endif
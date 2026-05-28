`ifndef __one_long_push_button_sequence
`define __one_long_push_button_sequence

class one_long_push_button_sequence extends uvm_sequence #(button_transaction);
  
  //add sequence to the UVM database
  `uvm_object_utils(one_long_push_button_sequence)
  
  rand int nr_of_trans;

  //constrains the number of transactions
  constraint nr_of_trans_c{
    soft nr_of_trans == 1;
  }
  
  function new(string name="one_long_push_button_sequence");
    super.new(name);
  endfunction
    
  function void post_randomize();
    `uvm_info("one_long_push_button_sequence", $sformatf("Number of transactions=%0d", nr_of_trans), UVM_DEBUG)
  endfunction
  
  virtual task body();
    for (int i=0; i< nr_of_trans; i++) begin
      req = button_transaction::type_id::create("req");
      
      start_item(req);
      req.button = LONG_PUSH_BUTTON;
      `uvm_info("one_long_push_button_sequence", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    `uvm_info("one_long_push_button_sequence", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask
endclass
`endif
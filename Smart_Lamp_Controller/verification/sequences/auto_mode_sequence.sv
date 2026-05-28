`ifndef __auto_mode_sequence
`define __auto_mode_sequence

class auto_mode_sequence extends uvm_sequence #(button_transaction);
  
  //add sequence to the UVM database
  `uvm_object_utils(auto_mode_sequence)
  
  rand int nr_of_trans;
  
  //constrains the number of transactions
  constraint nr_of_trans_c{
    soft nr_of_trans == 1;
  }
  
  function new(string name="auto_mode_sequence");
    super.new(name);
  endfunction
    
  function void post_randomize();
    `uvm_info("AUTO_MODE_SEQUENCE", $sformatf("Number of transactions=%0d", nr_of_trans), UVM_DEBUG)
  endfunction
  
  virtual task body();
    for (int i=0; i< nr_of_trans; i++) begin
      req = button_transaction::type_id::create("req");
      
      start_item(req);
      req.button = SHORT_PUSH_BUTTON;
      `uvm_info("AUTO_MODE_SEQUENCE", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    `uvm_info("AUTO_MODE_SEQUENCE", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask
endclass
`endif
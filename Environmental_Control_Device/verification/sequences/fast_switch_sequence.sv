`ifndef __fast_switch_sequence
`define __fast_switch_sequence


`include "../defines.sv"

class fast_switch_sequence extends uvm_sequence #(button_transaction);
  
  //add sequence to the UVM database
  `uvm_object_utils(fast_switch_sequence)
 
  rand int nr_of_trans;
  
  //constrains the number of transactions
  constraint nr_of_trans_c{
    soft nr_of_trans inside {[`MIN_TRANSACTION_NR:`MIN_TRANSACTION_NR+5]};
  }
  
  function new(string name="fast_switch_sequence");
    super.new(name);
  endfunction
    
  function void post_randomize();
    `uvm_info("FAST_SWITCH_SEQUENCE", $sformatf("Number of transactions=%0d", nr_of_trans), UVM_DEBUG)
  endfunction
  
  virtual task body();
    for (int i=0; i< nr_of_trans; i++) begin
      req = button_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {i%2 ==0 -> enable == 1; 
                                    i%2 ==1 -> enable == 0;});
      if(i == nr_of_trans-1) //last transaction must have enable = 1, to allow the system to work and thus to be able to send all the transactions of temperature
        req.enable = 1;
      `uvm_info("FAST_SWITCH_SEQUENCE", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    `uvm_info("FAST_SWITCH_SEQUENCE", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask

endclass : fast_switch_sequence

`endif
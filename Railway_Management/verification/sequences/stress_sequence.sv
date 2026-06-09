`ifndef __stress_sequence
`define __stress_sequence

`include "../defines.sv"

class stress_sequence extends uvm_sequence #(trains_transaction);
  
  //add sequence to the UVM database
  `uvm_object_utils(stress_sequence)
  
  rand int nr_of_trans;
  
  //constrains the number of transactions
  constraint nr_of_trans_c{
    soft nr_of_trans  inside {[`MIN_TRANSACTION_NR:`MIN_TRANSACTION_NR+5]};
  }
  
  function new(string name="stress_sequence");
    super.new(name);
  endfunction
    
  function void post_randomize();
    `uvm_info("STRESS_SEQUENCE", $sformatf("Number of transactions=%0d", nr_of_trans), UVM_DEBUG)
  endfunction
  
  virtual task body();
    for (int i=0; i< nr_of_trans; i++) begin
      req = trains_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {t1_i dist { 0:= 2, 1:= 8}; 
                                    t2_i dist { 0:= 2, 1:= 8}; 
                                    t3_i dist { 0:= 2, 1:= 8}; 
                                    t4_i dist { 0:= 2, 1:= 8}; 
                                    t5_i dist { 0:= 2, 1:= 8}; 
                                    t6_i dist { 0:= 2, 1:= 8};});
      `uvm_info("STRESS_SEQUENCE", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    
    //last transaction with all fields set to 0, to signal the end of the sequence
    req = trains_transaction::type_id::create("req");
    start_item(req);
    finish_item(req);
    
    `uvm_info("STRESS_SEQUENCE", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask

endclass : stress_sequence

`endif
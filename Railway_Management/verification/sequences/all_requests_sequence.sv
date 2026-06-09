`ifndef __all_requests_sequence
`define __all_requests_sequence

`include "../defines.sv"

class all_requests_sequence extends uvm_sequence #(trains_transaction);
  
  //add sequence to the UVM database
  `uvm_object_utils(all_requests_sequence)
  
  rand int nr_of_trans;
  
  //constrains the number of transactions
  constraint nr_of_trans_c{
    soft nr_of_trans  inside {[`MIN_TRANSACTION_NR:`MIN_TRANSACTION_NR+5]};
  }
  
  function new(string name="all_requests_sequence");
    super.new(name);
  endfunction
    
  function void post_randomize();
    `uvm_info("ALL_REQUESTS_SEQUENCE", $sformatf("Number of transactions=%0d", nr_of_trans), UVM_DEBUG)
  endfunction
  
  virtual task body();
    for (int i=0; i< nr_of_trans; i++) begin
      req = trains_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {(i%2==0) -> (t1_i == 1 && t2_i == 1 && t3_i == 1 && t4_i == 1 && t5_i == 1 && t6_i == 1);   //all trains
                                    (i%2==1) -> (t1_i == 0 && t2_i == 0 && t3_i == 0 && t4_i == 0 && t5_i == 0 && t6_i == 0);});//no train
      `uvm_info("ALL_REQUESTS_SEQUENCE", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    
    //last transaction with all fields set to 0, to signal the end of the sequence
    req = trains_transaction::type_id::create("req");
    start_item(req);
    finish_item(req);
    
    `uvm_info("ALL_REQUESTS_SEQUENCE", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask

endclass : all_requests_sequence

`endif
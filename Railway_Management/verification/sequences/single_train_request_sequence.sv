`ifndef __single_train_request_sequence
`define __single_train_request_sequence

class single_train_request_sequence extends uvm_sequence #(trains_transaction);
  
  //add sequence to the UVM database
  `uvm_object_utils(single_train_request_sequence)
  
  rand int nr_of_trans;
  
  //constrains the number of transactions
  constraint nr_of_trans_c{
    soft nr_of_trans == 11;
  }
  
  function new(string name="single_train_request_sequence");
    super.new(name);
  endfunction
    
  function void post_randomize();
    `uvm_info("SINGLE_TRAIN_REQUEST_SEQUENCE", $sformatf("Number of transactions=%0d", nr_of_trans), UVM_DEBUG)
  endfunction
  
  virtual task body();
    for (int i=0; i< nr_of_trans; i++) begin
      req = trains_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {(i==0)  -> (t1_i == 1 && t2_i == 0 && t3_i == 0 && t4_i == 0 && t5_i == 0 && t6_i == 0); //T1
                                    (i==2)  -> (t1_i == 0 && t2_i == 1 && t3_i == 0 && t4_i == 0 && t5_i == 0 && t6_i == 0); //T2
                                    (i==4)  -> (t1_i == 0 && t2_i == 0 && t3_i == 1 && t4_i == 0 && t5_i == 0 && t6_i == 0); //T3
                                    (i==6)  -> (t1_i == 0 && t2_i == 0 && t3_i == 0 && t4_i == 1 && t5_i == 0 && t6_i == 0); //T4
                                    (i==8)  -> (t1_i == 0 && t2_i == 0 && t3_i == 0 && t4_i == 0 && t5_i == 1 && t6_i == 0); //T5
                                    (i==10) -> (t1_i == 0 && t2_i == 0 && t3_i == 0 && t4_i == 0 && t5_i == 0 && t6_i == 1); //T6
                                    //no train
                                    (i%2==1) -> (t1_i == 0 && t2_i == 0 && t3_i == 0 && t4_i == 0 && t5_i == 0 && t6_i == 0);});
      `uvm_info("SINGLE_TRAIN_REQUEST_SEQUENCE", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    
    //last transaction with all fields set to 0, to signal the end of the sequence
    req = trains_transaction::type_id::create("req");
    start_item(req);
    finish_item(req);
    
    `uvm_info("SINGLE_TRAIN_REQUEST_SEQUENCE", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask

endclass : single_train_request_sequence

`endif
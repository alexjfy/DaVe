`ifndef __same_parity_priority_sequence
`define __same_parity_priority_sequence

class same_parity_priority_sequence extends uvm_sequence #(trains_transaction);
  
  //add sequence to the UVM database
  `uvm_object_utils(same_parity_priority_sequence)
  
  rand int nr_of_trans;
  
  //constrains the number of transactions
  constraint nr_of_trans_c{
    soft nr_of_trans == 7;
  }
  
  function new(string name="same_parity_priority_sequence");
    super.new(name);
  endfunction
    
  function void post_randomize();
    `uvm_info("SAME_PARITY_PRIORITY_SEQUENCE", $sformatf("Number of transactions=%0d", nr_of_trans), UVM_DEBUG)
  endfunction
  
  virtual task body();
    for (int i=0; i< nr_of_trans; i++) begin
      req = trains_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {(i==0)  -> (t1_i == 1 && t2_i == 0 && t3_i == 1 && t4_i == 0 && t5_i == 0 && t6_i == 0);    //T1 has priority over T3
                                    (i==1)  -> (t1_i == 1 && t2_i == 0 && t3_i == 0 && t4_i == 0 && t5_i == 1 && t6_i == 0);    //T1 has priority over T5
                                    (i==2)  -> (t1_i == 0 && t2_i == 0 && t3_i == 1 && t4_i == 0 && t5_i == 1 && t6_i == 0);    //T3 has priority over T5
                                    (i==3)  -> (t1_i == 0 && t2_i == 0 && t3_i == 0 && t4_i == 0 && t5_i == 0 && t6_i == 0);    //no train
                                    (i==4)  -> (t1_i == 0 && t2_i == 1 && t3_i == 0 && t4_i == 1 && t5_i == 0 && t6_i == 0);    //T2 has priority over T4
                                    (i==5)  -> (t1_i == 0 && t2_i == 1 && t3_i == 0 && t4_i == 0 && t5_i == 0 && t6_i == 1);    //T2 has priority over T6
                                    (i==6)  -> (t1_i == 0 && t2_i == 0 && t3_i == 0 && t4_i == 1 && t5_i == 0 && t6_i == 1);}); //T4 has priority over T6
      `uvm_info("SAME_PARITY_PRIORITY_SEQUENCE", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    
    //last transaction with all fields set to 0, to signal the end of the sequence
    req = trains_transaction::type_id::create("req");
    start_item(req);
    finish_item(req);
    
    `uvm_info("SAME_PARITY_PRIORITY_SEQUENCE", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask

endclass : same_parity_priority_sequence

`endif
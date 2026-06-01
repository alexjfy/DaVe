`ifndef __humidity_sequence
`define __humidity_sequence

class humidity_sequence extends uvm_sequence #(sensor_transaction);
  
  //add sequence to the UVM database
  `uvm_object_utils(humidity_sequence)
 
  rand int nr_of_trans;
  
  //constrains the number of transactions
  constraint nr_of_trans_c{
    soft nr_of_trans inside {[`MIN_TRANSACTION_NR:`MIN_TRANSACTION_NR+5]};
  }
  
  function new(string name="humidity_sequence");
    super.new(name);
  endfunction
    
  function void post_randomize();
    `uvm_info("HUMIDITY_SEQUENCE", $sformatf("Number of transactions=%0d", nr_of_trans), UVM_DEBUG)
  endfunction
  
  virtual task body();
    for (int i=0; i< nr_of_trans; i++) begin
      req = sensor_transaction::type_id::create("req");
      
      start_item(req); 
      assert (req.randomize() with {//min value
                                    (i % 6) == 0 -> humidity == 0;
              						          //off values
                                    (i % 6) == 1 -> humidity inside {[1:34]};
              						          //limit values
                                    (i % 6) == 2 -> humidity == 35;
                                    (i % 6) == 3 -> humidity == 50;
              						          //on values
                                    (i % 6) == 4 -> humidity inside {[51:99]};
                                    //max value  
                                    (i % 6) == 5 -> humidity == 100;});
      `uvm_info("HUMIDITY_SEQUENCE", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    `uvm_info("HUMIDITY_SEQUENCE", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask

endclass : humidity_sequence

`endif
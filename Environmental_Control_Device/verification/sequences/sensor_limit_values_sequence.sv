`ifndef __sensor_limit_values_sequence
`define __sensor_limit_values_sequence

class sensor_limit_values_sequence extends uvm_sequence #(sensor_transaction);
  
  //add sequence to the UVM database
  `uvm_object_utils(sensor_limit_values_sequence)
 
  rand int nr_of_trans;
  
  //constrains the number of transactions
  constraint nr_of_trans_c{
    soft nr_of_trans inside {[`MIN_TRANSACTION_NR:`MIN_TRANSACTION_NR+5]};
  }
  
  function new(string name="sensor_limit_values_sequence");
    super.new(name);
  endfunction
    
  function void post_randomize();
    `uvm_info("SENSOR_LIMIT_VALUES_SEQUENCE", $sformatf("Number of transactions=%0d", nr_of_trans), UVM_DEBUG)
  endfunction
  
  virtual task body();
    for (int i=0; i< nr_of_trans; i++) begin
      req = sensor_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {(i % 4) == 0 -> temperature == 0; 
              						          (i % 4) == 0 -> humidity == 0;
              						          (i % 4) == 0 -> luminous_intensity == 0;
              						          //limit values
                                    (i % 4) == 1 -> temperature == 22;
                                    (i % 4) == 1 -> humidity == 35;
                                    (i % 4) == 1 -> luminous_intensity == 200;
                                    (i % 4) == 2 -> temperature == 25;
                                    (i % 4) == 2 -> humidity == 50;
                                    (i % 4) == 2 -> luminous_intensity == 700;
                                    //max values  
                                    (i % 4) == 3 -> temperature == 40;
                                    (i % 4) == 3 -> humidity == 100;
                                    (i % 4) == 3 -> luminous_intensity == 900;});
      								
      `uvm_info("SENSOR_LIMIT_VALUES_SEQUENCE", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    `uvm_info("SENSOR_LIMIT_VALUES_SEQUENCE", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask 

endclass : sensor_limit_values_sequence

`endif
`ifndef __temperature_sequence
`define __temperature_sequence

class temperature_sequence extends uvm_sequence #(sensor_transaction);
  
  //add sequence to the UVM database
  `uvm_object_utils(temperature_sequence)
 
  rand int nr_of_trans;
  
  //constrains the number of transactions
  constraint nr_of_trans_c{
    soft nr_of_trans inside {[`MIN_TRANSACTION_NR:`MIN_TRANSACTION_NR+5]};
  }
  
  function new(string name="temperature_sequence");
    super.new(name);
  endfunction
    
  function void post_randomize();
    `uvm_info("TEMPERATURE_SEQUENCE", $sformatf("Number of transactions=%0d", nr_of_trans), UVM_DEBUG)
  endfunction
  
  virtual task body();
    for (int i=0; i< nr_of_trans; i++) begin
      req = sensor_transaction::type_id::create("req");
      start_item(req);
      assert (req.randomize() with {//min value
                                    (i % 6) == 0 -> temperature == 0;
              						          //off values
                                    (i % 6) == 1 -> temperature inside {[1:21]};
              						          //limit values
                                    (i % 6) == 2 -> temperature == 22;
                                    (i % 6) == 3 -> temperature == 23;
              						          //on values
                                    (i % 6) == 4 -> temperature inside {[24:39]};
                                    //max value  
                                    (i % 6) == 5 -> temperature == 40;});
      `uvm_info("TEMPERATURE_SEQUENCE", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    `uvm_info("TEMPERATURE_SEQUENCE", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask

endclass : temperature_sequence

`endif
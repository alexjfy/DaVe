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
      assert (req.randomize() with {
        i == 0 -> sensor == 0;
        i == 1 -> sensor == 63;
        i == 2 -> sensor == 64;
        i == 3 -> sensor == 127;
        i == 4 -> sensor == 128;
        i == 5 -> sensor == 191;
        i == 6 -> sensor == 192;
        i == 7 -> sensor == 255;
      });
      `uvm_info("SENSOR_LIMIT_VALUES_SEQUENCE", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    `uvm_info("SENSOR_LIMIT_VALUES_SEQUENCE", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask
endclass
`endif
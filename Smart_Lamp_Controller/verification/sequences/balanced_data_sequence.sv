`ifndef __balanced_data_sequence
`define __balanced_data_sequence

class balanced_data_sequence extends uvm_sequence #(sensor_transaction);
  
  //add sequence to the UVM database
  `uvm_object_utils(balanced_data_sequence)
  
  rand int nr_of_trans;
  
  //constrains the number of transactions
  constraint nr_of_trans_c{
    soft nr_of_trans == 100;
  }
  
  function new(string name="balanced_data_sequence");
    super.new(name);
  endfunction
    
  function void post_randomize();
    `uvm_info("BALANCED_DATA_SEQUENCE", $sformatf("Number of transactions=%0d", nr_of_trans), UVM_DEBUG)
  endfunction
  
  virtual task body();
    for (int i=0; i< nr_of_trans; i++) begin
      req = sensor_transaction::type_id::create("req");
      
      start_item(req);
      assert (req.randomize() with {i%4 == 0 -> sensor inside {[192:255]};
                                    i%4 == 1 -> sensor inside {[128:191]};
                                    i%4 == 2 -> sensor inside {[64:127]};
                                    i%4 == 3 -> sensor inside {[0:63]};
                                   });
      `uvm_info("BALANCED_DATA_SEQUENCE", $sformatf("Transaction %0d generated:\n %s", i, req.sprint()), UVM_LOW)
      finish_item(req);
    end
    `uvm_info("BALANCED_DATA_SEQUENCE", $sformatf("%0d transactions generated", nr_of_trans), UVM_LOW)
  endtask
endclass
`endif
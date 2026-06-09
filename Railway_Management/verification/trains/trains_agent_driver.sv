`ifndef __trains_driver
`define __trains_driver

class trains_agent_driver extends uvm_driver #(trains_transaction);
  
  //add driver to the UVM database
  `uvm_component_utils (trains_agent_driver)
  
  virtual trains_interface trains_vif;
  
  //declare the class constructor;
  function new(string name = "trains_agent_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual trains_interface)::get(this, "", "trains_interface", trains_vif))begin
      `uvm_fatal("TRAINS_AGENT_DRIVER", {"Virtual interface must be set for: ",get_full_name(),".trains_vif"})
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    drive_reset_values();
    // initial reset
    @(negedge trains_vif.rst);
    `uvm_info("TRAINS_AGENT_DRIVER", $sformatf("Trains driver after reset"), UVM_MEDIUM)
    fork
      get_and_drive();
    join
  endtask

  //idle values for driven signals
  task drive_reset_values();
    `uvm_info("TRAINS_AGENT_DRIVER", $sformatf("Trains driver reset"), UVM_MEDIUM)
    trains_vif.t_1 <= 'b0;
    trains_vif.t_2 <= 'b0;
    trains_vif.t_3 <= 'b0;
    trains_vif.t_4 <= 'b0;
    trains_vif.t_5 <= 'b0;
    trains_vif.t_6 <= 'b0;
  endtask
  
  task get_and_drive();
    forever begin
      `uvm_info("TRAINS_AGENT_DRIVER", $sformatf("Waiting for transaction from sequencer"), UVM_LOW)
      seq_item_port.get_next_item(req);
      `uvm_info("TRAINS_AGENT_DRIVER", $sformatf("Transaction received from sequencer"), UVM_LOW)
      send_transaction(req);
      `uvm_info("TRAINS_AGENT_DRIVER", $sformatf("Transaction sent to interface"), UVM_LOW)
      seq_item_port.item_done();
    end
  endtask
  
  task send_transaction(trains_transaction trains_trans);
    @(posedge trains_vif.clk);
    trains_vif.t_1 = trains_trans.t1_i;
    trains_vif.t_2 = trains_trans.t2_i;
    trains_vif.t_3 = trains_trans.t3_i;
    trains_vif.t_4 = trains_trans.t4_i;
    trains_vif.t_5 = trains_trans.t5_i;
    trains_vif.t_6 = trains_trans.t6_i;
  endtask
  
endclass : trains_agent_driver

`endif
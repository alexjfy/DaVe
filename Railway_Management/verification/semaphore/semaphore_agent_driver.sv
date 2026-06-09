`ifndef __semaphore_driver
`define __semaphore_driver

class semaphore_agent_driver extends uvm_driver #(semaphore_transaction);
  
  //add driver to the UVM database
  `uvm_component_utils (semaphore_agent_driver)
  
  virtual semaphore_interface semaphore_vif;
  
  //declare the class constructor;
  function new(string name = "semaphore_agent_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual semaphore_interface)::get(this, "", "semaphore_interface", semaphore_vif))begin
      `uvm_fatal("SEMAPHORE_AGENT_DRIVER", {"Virtual interface must be set for: ",get_full_name(),".semaphore_vif"})
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    drive_reset_values();
    // initial reset
    @(negedge semaphore_vif.rst);
    `uvm_info("SEMAPHORE_AGENT_DRIVER", $sformatf("Semaphore driver after reset"), UVM_MEDIUM)
    fork
      get_and_drive();
    join
  endtask

  //idle values for driven signals
  task drive_reset_values();
    `uvm_info("SEMAPHORE_AGENT_DRIVER", $sformatf("Semaphore driver reset"), UVM_MEDIUM)
    semaphore_vif.even_semaphore <= 'b0;
    semaphore_vif.odd_semaphore <= 'b0;
  endtask
  
  task get_and_drive();
    forever begin
      `uvm_info("SEMAPHORE_AGENT_DRIVER", $sformatf("Waiting for transaction from sequencer"), UVM_LOW)
      seq_item_port.get_next_item(req);
      `uvm_info("SEMAPHORE_AGENT_DRIVER", $sformatf("Transaction received from sequencer"), UVM_LOW)
      send_transaction(req);
      `uvm_info("SEMAPHORE_AGENT_DRIVER", $sformatf("Transaction sent to interface"), UVM_LOW)
      seq_item_port.item_done();
    end
  endtask
  
  task send_transaction(semaphore_transaction trans);
    @(posedge semaphore_vif.clk);  //syncronize with the clock before driving the signals
    semaphore_vif.even_semaphore = trans.even_semaphore_state;
    semaphore_vif.odd_semaphore  = trans.odd_semaphore_state;
  endtask
  
endclass : semaphore_agent_driver

`endif
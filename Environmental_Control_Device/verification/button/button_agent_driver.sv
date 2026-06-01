`ifndef __button_driver
`define __button_driver

class button_agent_driver extends uvm_driver #(button_transaction);
  
  //add driver to the UVM database
  `uvm_component_utils (button_agent_driver)
  
  virtual button_interface button_vif;
  
  //declare the class constructor;
  function new(string name = "button_agent_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual button_interface)::get(this, "", "button_interface", button_vif))begin
      `uvm_fatal("BUTTON_AGENT_DRIVER", {"Virtual interface must be set for: ",get_full_name(),".button_vif"})
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    drive_reset_values();
    // initial reset
    @(negedge button_vif.reset_i);
    `uvm_info("BUTTON_AGENT_DRIVER", $sformatf("Button driver after reset"), UVM_MEDIUM)
    fork
      get_and_drive();
    join
  endtask

  //idle values for driven signals
  task drive_reset_values();
    `uvm_info("BUTTON_AGENT_DRIVER", $sformatf("Button driver reset"), UVM_MEDIUM)
    button_vif.enable_i <= 'b0;
  endtask
  
  task get_and_drive();
    forever begin
      `uvm_info("BUTTON_AGENT_DRIVER", $sformatf("Waiting for transaction from sequencer"), UVM_LOW)
      seq_item_port.get_next_item(req);
      `uvm_info("BUTTON_AGENT_DRIVER", $sformatf("Transaction received from sequencer"), UVM_LOW)
      send_transaction(req);
      `uvm_info("BUTTON_AGENT_DRIVER", $sformatf("Transaction sent to interface"), UVM_LOW)
      seq_item_port.item_done();
    end
  endtask
   
  task send_transaction(button_transaction trans);
    @(posedge button_vif.clk_i);  //syncronize with the clock before driving the signals
    button_vif.enable_i = trans.enable;        
  endtask
  
endclass : button_agent_driver

`endif
`ifndef __sensor_driver
`define __sensor_driver

class sensor_agent_driver extends uvm_driver #(sensor_transaction);
  
  //add driver to the UVM database
  `uvm_component_utils (sensor_agent_driver)
  
  virtual sensor_interface sensor_vif;
  
  //declare the class constructor;
  function new(string name = "sensor_agent_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sensor_interface)::get(this, "", "sensor_interface", sensor_vif))begin
      `uvm_fatal("SENSOR_AGENT_DRIVER", {"Virtual interface must be set for: ",get_full_name(),".sensor_vif"})
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    drive_reset_values();
    // initial reset
    @(negedge sensor_vif.reset_i);
    `uvm_info("SENSOR_AGENT_DRIVER", $sformatf("Sensor driver after reset"), UVM_MEDIUM)
    fork
      get_and_drive();
    join
  endtask

  //idle values for driven signals
  task drive_reset_values();
    `uvm_info("SENSOR_AGENT_DRIVER", $sformatf("Sensor driver reset"), UVM_MEDIUM)
    sensor_vif.valid_i <= 'b0;
    sensor_vif.temperature_i <= 'b0;
    sensor_vif.humidity_i <= 'b0;
    sensor_vif.luminous_intensity_i <= 'b0;
  endtask
  
  task get_and_drive();
    forever begin
      `uvm_info("SENSOR_AGENT_DRIVER", $sformatf("Waiting for transaction from sequencer"), UVM_LOW)
      seq_item_port.get_next_item(req);
      `uvm_info("SENSOR_AGENT_DRIVER", $sformatf("Transaction received from sequencer"), UVM_LOW)
      send_transaction(req);
      `uvm_info("SENSOR_AGENT_DRIVER", $sformatf("Transaction sent to interface"), UVM_LOW)
      seq_item_port.item_done();
    end
  endtask
  
  task send_transaction(sensor_transaction sensor_trans);    
    `uvm_info("SENSOR_AGENT_DRIVER", $sformatf("Waiting for ready signal"), UVM_DEBUG)
    wait(sensor_vif.ready_o)
    `uvm_info("SENSOR_AGENT_DRIVER", $sformatf("READY signal received"), UVM_DEBUG)
    @(posedge sensor_vif.clk_i);
    sensor_vif.valid_i = 'b1;
    sensor_vif.temperature_i = sensor_trans.temperature;
    sensor_vif.humidity_i = sensor_trans.humidity;
    sensor_vif.luminous_intensity_i = sensor_trans.luminous_intensity;
	 @(posedge sensor_vif.clk_i);
    sensor_vif.valid_i = 'b0;
  endtask
  
endclass : sensor_agent_driver

`endif
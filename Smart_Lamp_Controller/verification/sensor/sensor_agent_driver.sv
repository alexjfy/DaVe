`ifndef __sensor_driver
`define __sensor_driver

class sensor_agent_driver extends uvm_driver #(sensor_transaction);
  
  //add driver to the UVM database
  `uvm_component_utils (sensor_agent_driver)
  
  virtual sensor_interface sensor_driver_if;
  
  //declare the class constructor;
  function new(string name = "sensor_agent_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sensor_interface)::get(this, "", "sensor_interface", sensor_driver_if))begin
      `uvm_fatal("SENSOR_DRIVER_AGENT", {"Virtual interface must be set for: ",get_full_name(),".sensor_driver_if"})
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    drive_reset_values();
    // initial reset
    @(negedge sensor_driver_if.rst);
    @(posedge sensor_driver_if.rst);
    `uvm_info("SENSOR_DRIVER_AGENT", $sformatf("Sensor driver after reset"), UVM_MEDIUM)
    fork
      get_and_drive();
    join
  endtask

  //idle values for driven signals
  task drive_reset_values();
    `uvm_info("SENSOR_DRIVER_AGENT", $sformatf("Sensor driver reset"), UVM_MEDIUM)
    sensor_driver_if.valid      <= 'b0;
    sensor_driver_if.brightness <= 'b0;
  endtask
  
  task get_and_drive();
    forever begin
      `uvm_info("SENSOR_DRIVER_AGENT", $sformatf("Waiting for transaction from sequencer"), UVM_LOW)
      seq_item_port.get_next_item(req);
      `uvm_info("SENSOR_DRIVER_AGENT", $sformatf("Received transaction from sequencer"), UVM_LOW)
      send_transaction(req);
      `uvm_info("SENSOR_DRIVER_AGENT", $sformatf("Transaction sent to interface"), UVM_LOW)
      seq_item_port.item_done();
    end
  endtask
  
  task send_transaction(sensor_transaction sensor_trans);
    do @(posedge sensor_driver_if.clk); //data is transmitted on the posedge clock
    while( sensor_driver_if.ready == 0);
    sensor_driver_if.valid <= 1;
    sensor_driver_if.brightness <= sensor_trans.sensor;
    `uvm_info("SENSOR_DRIVER_AGENT", $sformatf("%0t : ready value = %0b and valid value = %0b", $realtime, sensor_driver_if.ready, sensor_driver_if.valid ), UVM_DEBUG)
    @(posedge sensor_driver_if.clk);
    sensor_driver_if.valid <= 0;
    `uvm_info("SENSOR_DRIVER_AGENT", $sformatf("After transmission [T=%0t]", $realtime), UVM_DEBUG)
  endtask
  
endclass : sensor_agent_driver

`endif
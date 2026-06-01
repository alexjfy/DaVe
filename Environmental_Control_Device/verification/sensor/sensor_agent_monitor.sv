`ifndef __sensor_monitor
`define __sensor_monitor

class sensor_agent_monitor extends uvm_monitor;
  
  //the monitor is added to the database of this project;
  `uvm_component_utils (sensor_agent_monitor) 
  
  sensor_coverage                         sensor_coverage_inst; 
  uvm_analysis_port #(sensor_transaction) sensor_monitor_port;
  virtual sensor_interface                sensor_vif;
  sensor_transaction                      sensor_trans, aux;
  
  //declare the class constructor;
  function new(string name = "sensor_agent_monitor", uvm_component parent = null);
    super.new(name, parent);
    sensor_monitor_port = new("sensor_monitor_port",this);
    sensor_coverage_inst = sensor_coverage::type_id::create ("sensor_coverage_inst", this);
    sensor_trans = sensor_transaction::type_id::create("sensor_trans");
    aux = sensor_transaction::type_id::create("aux");
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sensor_interface)::get(this, "", "sensor_interface", sensor_vif))
        `uvm_fatal("SENSOR_MONITOR_AGENT", {"Virtual interface must be set for: ",get_full_name(),".sensor_vif"})
  endfunction
    
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    sensor_coverage_inst.p_monitor = this;
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    //wait for reset
    @(negedge sensor_vif.reset_i);
    @(sensor_vif.clk_i);
    fork
      collect_and_send();
    join_none
  endtask
  
  //task for collecting data from the interface and sending transactions to the scoreboard
  task collect_and_send();   
    forever begin
      @(posedge sensor_vif.valid_i); 
      sensor_trans.temperature = sensor_vif.temperature_i;
      sensor_trans.humidity = sensor_vif.humidity_i;
	    sensor_trans.luminous_intensity = sensor_vif.luminous_intensity_i;      
	    @(negedge sensor_vif.clk_i);
      send_transaction(sensor_trans);
    end
  endtask
						
  //task for sending transactions																			   
  task send_transaction(sensor_transaction trans);
    aux.copy(sensor_trans); 
    sensor_monitor_port.write(aux);
    sensor_coverage_inst.sensor_cg.sample();
  endtask	  
  
endclass: sensor_agent_monitor

`endif
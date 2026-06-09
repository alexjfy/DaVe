`ifndef __trains_monitor
`define __trains_monitor

class trains_agent_monitor extends uvm_monitor;

  //the monitor is added to the database of this project;
  `uvm_component_utils (trains_agent_monitor)
  
  virtual trains_interface                trains_vif;
  uvm_analysis_port #(trains_transaction) trains_monitor_port;
  trains_coverage                         trains_coverage_inst;  
  trains_transaction                      trains_trans, aux;
  
  //declare the class constructor;
  function new(string name = "trains_agent_monitor", uvm_component parent = null);
    super.new(name, parent);
    trains_monitor_port = new("trains_monitor_port",this);
    trains_trans = trains_transaction::type_id::create("trains_trans");
    aux = trains_transaction::type_id::create("aux");
    trains_coverage_inst = trains_coverage::type_id::create ("trains_coverage_inst", this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual trains_interface)::get(this, "", "trains_interface", trains_vif))
      `uvm_fatal("TRAINS_AGENT_MONITOR", {"Virtual interface must be set for: ",get_full_name(),".trains_vif"})
  endfunction
      
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
	  trains_coverage_inst.p_monitor = this;
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    //wait for reset
    @(negedge trains_vif.rst);
    fork
      collect_and_send();
    join_none
  endtask
  
  task collect_and_send();
    forever begin
      @(negedge trains_vif.clk); //syncronize with the clock before sampling the signals
      trains_trans.t1_i = trains_vif.t_1;
      trains_trans.t2_i = trains_vif.t_2;
      trains_trans.t3_i = trains_vif.t_3;
      trains_trans.t4_i = trains_vif.t_4;
      trains_trans.t5_i = trains_vif.t_5;
      trains_trans.t6_i = trains_vif.t_6;
      
      trains_monitor_port.write(trains_trans); 
      trains_coverage_inst.trains_requests_cg.sample();
    end
  endtask  
  
endclass : trains_agent_monitor

`endif
`ifndef __button_monitor
`define __button_monitor
`include "button_transaction.sv"

class button_agent_monitor extends uvm_monitor;
  
  //the monitor is added to the database of this project;
  `uvm_component_utils (button_agent_monitor) 
  
  button_coverage                         button_coverage_inst;
  uvm_analysis_port #(button_transaction) button_monitor_port;
  virtual button_interface                button_vif;
  button_transaction                      button_trans, aux;
  
  //declare the class constructor;
  function new(string name = "button_agent_monitor", uvm_component parent = null);
    super.new(name, parent);
    button_monitor_port = new("button_monitor_port",this);
    button_coverage_inst = button_coverage::type_id::create ("button_coverage_inst", this);
    button_trans = button_transaction::type_id::create("button_trans");
    aux = button_transaction::type_id::create("aux");
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual button_interface)::get(this, "", "button_interface", button_vif))
      `uvm_fatal("BUTTON_AGENT_MONITOR", {"Virtual interface must be set for: ",get_full_name(),".button_vif"})
  endfunction
        
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    button_coverage_inst.p_monitor = this;
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    //wait for reset
    @(negedge button_vif.reset_i);
    @(button_vif.clk_i);
    fork
      collect_and_send();
    join_none
  endtask
  
  task collect_and_send();    
    forever begin
      @(button_vif.enable_i);
      button_trans.enable = button_vif.enable_i;
      send_transaction(button_trans);
    end
  endtask
						
  //task for sending transactions																			   
  task send_transaction(button_transaction trans);
    aux.copy(button_trans);
    button_monitor_port.write(aux);
    button_coverage_inst.button_cg.sample();
  endtask	
  
endclass: button_agent_monitor

`endif
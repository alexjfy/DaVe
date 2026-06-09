`ifndef __semaphore_monitor
`define __semaphore_monitor
//`include "semaphore_transaction.sv"

class semaphore_agent_monitor extends uvm_monitor;
  
  //the monitor is added to the database of this project;
  `uvm_component_utils (semaphore_agent_monitor) 
  
  semaphore_coverage                         semaphore_coverage_inst;
  uvm_analysis_port #(semaphore_transaction) semaphore_monitor_port;
  virtual semaphore_interface                semaphore_vif;
  semaphore_transaction                      semaphore_trans, aux;
  
  //declare the class constructor;
  function new(string name = "monitor_agent_semafoare", uvm_component parent = null);
    super.new(name, parent);
    semaphore_monitor_port = new("semaphore_monitor_port",this);
    semaphore_coverage_inst = semaphore_coverage::type_id::create ("semaphore_coverage_inst", this);
    semaphore_trans = semaphore_transaction::type_id::create("semaphore_trans");
    aux = semaphore_transaction::type_id::create("aux");
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual semaphore_interface)::get(this, "", "semaphore_interface", semaphore_vif))
      `uvm_fatal("SEMAPHORE_AGENT_MONITOR", {"Virtual interface must be set for: ",get_full_name(),".semaphore_vif"})
  endfunction
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    semaphore_coverage_inst.p_monitor = this;
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    //wait for reset
    @(negedge semaphore_vif.rst);
    @(semaphore_vif.clk);
    fork
      collect_and_send();
    join_none
  endtask
  
  task collect_and_send();
    forever begin
      @(negedge semaphore_vif.clk); //syncronize with clock
      semaphore_trans.even_semaphore_state = semaphore_vif.even_semaphore;
      semaphore_trans.odd_semaphore_state = semaphore_vif.odd_semaphore;
      semaphore_monitor_port.write(semaphore_trans); 
      semaphore_coverage_inst.semaphore_states_cg.sample();
    end
  endtask
  
endclass: semaphore_agent_monitor

`endif
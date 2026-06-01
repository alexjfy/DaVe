`ifndef __actuator_monitor
`define __actuator_monitor

class actuator_agent_monitor extends uvm_monitor;
  
  //the monitor is added to the database of this project;
  `uvm_component_utils (actuator_agent_monitor) 
  
  actuator_coverage actuator_coverage_inst;
  uvm_analysis_port #(actuator_transaction) actuator_monitor_port;
  virtual actuator_interface actuator_vif;
  
  actuator_transaction actuator_trans, aux;
  
  //declare the class constructor;
  function new(string name = "actuator_agent_monitor", uvm_component parent = null);
    super.new(name, parent);
    actuator_monitor_port = new("actuator_monitor_port",this);
    actuator_coverage_inst = actuator_coverage::type_id::create("actuator_coverage_inst", this);
    actuator_trans = actuator_transaction::type_id::create("actuator_trans");
    aux = actuator_transaction::type_id::create("aux");
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual actuator_interface)::get(this, "", "actuator_interface", actuator_vif))
      `uvm_fatal("ACTUATOR_AGENT_MONITOR", {"Virtual interface must be set for: ",get_full_name(),".actuator_vif"})
  endfunction
        
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    actuator_coverage_inst.p_monitor = this;
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    //wait for reset
    @(negedge actuator_vif.reset_i);
    @(actuator_vif.clk_i);
    fork
      collect_and_send();
    join_none
  endtask
  
  //task for collecting data from the interface and sending transactions to the scoreboard
  task collect_and_send();
    forever begin
      //preluarea datelor de pe interfata se face la fiecare front negativ de ceas
      // @(negedge actuator_vif.clk_i);
      @(actuator_vif.heat_o or actuator_vif.AC_o or actuator_vif.blinds_o or actuator_vif.dehumidifier_o);
      
      actuator_trans.Heat_i =  actuator_vif.heat_o;
      actuator_trans.AC_i =  actuator_vif.AC_o;
      actuator_trans.Blinds_i =  actuator_vif.blinds_o;
      actuator_trans.Dehumidifier_i =  actuator_vif.dehumidifier_o;
      
      send_transaction(actuator_trans);
    end
  endtask
						
  //task for sending transactions																			   
  task send_transaction(actuator_transaction trans);
    aux.copy(trans);
    actuator_monitor_port.write(aux);
    actuator_coverage_inst.actuator_cg.sample();
  endtask	
endclass: actuator_agent_monitor

`endif
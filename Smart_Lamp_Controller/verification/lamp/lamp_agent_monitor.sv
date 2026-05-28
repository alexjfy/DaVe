`ifndef __lamp_monitor
`define __lamp_monitor

class lamp_agent_monitor extends uvm_monitor;
  
  //the monitor is added to the database of this project;
  `uvm_component_utils (lamp_agent_monitor)
  
  virtual lamp_interface                lamp_monitor_if;
  uvm_analysis_port #(lamp_transaction) lamp_monitor_port;
  lamp_coverage                         lamp_coverage_inst;
  lamp_transaction                      lamp_trans, aux;
  
  //declare the class constructor;
  function new(string name = "lamp_agent_monitor", uvm_component parent = null);
    super.new(name, parent);
    lamp_monitor_port = new("lamp_monitor_port",this);
    lamp_coverage_inst = lamp_coverage::type_id::create ("lamp_coverage_inst", this);
    lamp_trans = lamp_transaction::type_id::create("lamp_trans");
    aux = lamp_transaction::type_id::create("aux");											
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual lamp_interface)::get(this, "", "lamp_interface", lamp_monitor_if))
      `uvm_fatal("LAMP_MONITOR_AGENT", {"Virtual interface must be set for: ",get_full_name(),".lamp_monitor_if"})
  endfunction
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    lamp_coverage_inst.p_monitor = this;
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    //wait for reset
    @(posedge lamp_monitor_if.rst);
    @(lamp_monitor_if.clk);
    fork
      collect_and_send();
    join_none
  endtask

  //task for collecting data from the interface and sending transactions to the scoreboard
  task collect_and_send();
    forever begin
      @(lamp_monitor_if.light_level);
      case(lamp_monitor_if.light_level)
        0: lamp_trans.light_level_out = LIGHT_OFF;
        1: lamp_trans.light_level_out = ON_LEVEL_0;
        2: lamp_trans.light_level_out = ON_LEVEL_1;
        3: lamp_trans.light_level_out = ON_LEVEL_2;
      endcase
      send_transaction(lamp_trans);
    end
  endtask
						
  //task for sending transactions																			   
  task send_transaction(lamp_transaction trans);
    aux.light_level_out = trans.light_level_out; 
    lamp_monitor_port.write(aux);
    lamp_coverage_inst.lamp_state_cg.sample();
  endtask															 
								  
endclass : lamp_agent_monitor

`endif
`ifndef __button_monitor
`define __button_monitor

class button_agent_monitor extends uvm_monitor;

  //the monitor is added to the database of this project;
  `uvm_component_utils (button_agent_monitor)
  
  virtual button_interface                button_monitor_if;
  uvm_analysis_port #(button_transaction) button_monitor_port;
  button_coverage                         button_coverage_inst;
  button_transaction                      button_trans, aux;
  
  int counter = 0;  //push time counter
  
  //declare the class constructor;
  function new(string name = "button_agent_monitor", uvm_component parent = null);
    super.new(name, parent);
    button_monitor_port = new("button_monitor_port",this);
    button_trans = button_transaction::type_id::create("button_trans");
    button_coverage_inst = button_coverage::type_id::create ("button_coverage_inst", this);
    aux = button_transaction::type_id::create("aux");
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual button_interface)::get(this, "", "button_interface", button_monitor_if))
      `uvm_fatal("BUTTON_MONITOR", {"Virtual interface must be set for: ",get_full_name(),".button_monitor_if"})
  endfunction
      
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
	  button_coverage_inst.p_monitor = this;
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    //wait for reset
    @(posedge button_monitor_if.rst);
    @(button_monitor_if.clk);
    fork
      collect_and_send();
    join_none
  endtask
  
  //task for collecting data from the interface and sending transactions to the scoreboard
  task collect_and_send();
    forever begin
      @(negedge button_monitor_if.clk); //data are sampled at the negative edge of the clock
      if (button_monitor_if.button == 1 ) begin //button not pressed
        button_trans.button = UNPUSHED_BUTTON;
        button_coverage_inst.button_cg.sample();
        `uvm_info(get_type_name(), $sformatf("button is not pressed"), UVM_DEBUG)
        counter = 0;
      end
      else begin //button is pressed
        button_trans.button = SHORT_PUSH_BUTTON; // initially, we consider that the button is short pressed
        while (button_monitor_if.button == 0) begin
          counter=counter+1;
          `uvm_info(get_type_name(), $sformatf("counter = %0d", counter), UVM_DEBUG)
          @(negedge button_monitor_if.clk);
          if (counter==20) begin //after 20 clock cycles of button pressed, we consider that the button is long pressed
            button_trans.button = LONG_PUSH_BUTTON;   
            send_transaction(button_trans);
          end
        end
        counter = 0;
        if (button_trans.button == SHORT_PUSH_BUTTON) begin
          send_transaction(button_trans);    
        end
      end
    end
  endtask 
  
  //task for sending transactions
  task send_transaction(button_transaction trans);
    aux.button = trans.button;
    button_monitor_port.write(aux);
    button_coverage_inst.button_cg.sample();
  endtask
  
endclass : button_agent_monitor

`endif
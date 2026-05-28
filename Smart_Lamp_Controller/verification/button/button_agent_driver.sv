`ifndef __button_driver
`define __button_driver

`include "../defines.sv"

class button_agent_driver extends uvm_driver #(button_transaction);

  //add driver to the UVM database
  `uvm_component_utils (button_agent_driver)

  virtual button_interface button_driver_if;
  
  //declare the class constructor;
  function new(string name = "button_agent_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual button_interface)::get(this, "", "button_interface", button_driver_if)) begin
      `uvm_fatal("BUTTON_AGENT_DRIVER", {"Virtual interface must be set for: ",get_full_name(),".button_driver_if"})
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    drive_reset_values();
    // initial reset
    @(posedge button_driver_if.rst);
    `uvm_info("BUTTON_AGENT_DRIVER", $sformatf("Button driver after reset"), UVM_MEDIUM)
    fork
      get_and_drive();
    join
  endtask

  //idle values for driven signals
  task drive_reset_values();
    `uvm_info("BUTTON_AGENT_DRIVER", $sformatf("Button driver reset"), UVM_MEDIUM)
    button_driver_if.button <= 'b1;
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
  
  task send_transaction(button_transaction button_trans);
    assert (`SHORT_PUSH_CLK_CYCLES <20); //short push button should be less than 20 clock cycles
    if(button_trans.button==LONG_PUSH_BUTTON) begin
      `uvm_info("BUTTON_AGENT_DRIVER", $sformatf("start long push button"), UVM_LOW)
      for (int i=0; i< `LONG_PUSH_CLK_CYCLES; i++) begin
        @(posedge button_driver_if.clk);
        `uvm_info("BUTTON_AGENT_DRIVER", $sformatf("one clock cycle of long button push has passed, i = %0d", i), UVM_DEBUG)
        button_driver_if.button <= 0; 
      end
      @(posedge button_driver_if.clk);
      button_driver_if.button <= 1;
      `uvm_info("BUTTON_AGENT_DRIVER", $sformatf("end of long push button"), UVM_LOW)
    end
    else if (button_trans.button==SHORT_PUSH_BUTTON) begin
      `uvm_info("BUTTON_AGENT_DRIVER", $sformatf("start short push button"), UVM_LOW)
      for (int i=0; i<`SHORT_PUSH_CLK_CYCLES; i++) begin
        @(posedge button_driver_if.clk);
        `uvm_info("BUTTON_AGENT_DRIVER", $sformatf("one clock cycle of short button push has passed, i = %0d", i), UVM_DEBUG)
        button_driver_if.button <= 0;
      end
      @(posedge button_driver_if.clk);
      button_driver_if.button <= 1;
      `uvm_info("BUTTON_AGENT_DRIVER", $sformatf("end of short push button"), UVM_LOW)
    end
    else if (button_trans.button==UNPUSHED_BUTTON) begin
      @(posedge button_driver_if.clk);
      button_driver_if.button <= 1;
    end      
  endtask
  
endclass : button_agent_driver

`endif
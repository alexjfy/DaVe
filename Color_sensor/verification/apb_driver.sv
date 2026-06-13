
`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV

import apb_pkg::*;
`include "uvm_macros.svh"

class apb_driver extends uvm_driver #(apb_trans);

  `uvm_component_utils(apb_driver)

  virtual apb_interface#(`APB_AW, `APB_DW) apb_vif;

  function new(string name,uvm_component parent = null);
    super.new(name,parent);
  endfunction:new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db#(virtual apb_interface#(`APB_AW, `APB_DW))::get(this,"","apb_vif", apb_vif)) begin
      `uvm_fatal(get_type_name(), {"Virtual interface must be set for: ",get_full_name(),".apb_vif"})
    end
  endfunction:build_phase


  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    @(negedge apb_vif.rst_n);
    wait_reset();

    forever begin
      //Initial reset
      if (!apb_vif.rst_n) begin
        `uvm_warning(get_type_name(), "\n\nWAIT RESET");
        @(posedge apb_vif.rst_n);
      end

      fork
        begin
          //Reset
          @(negedge apb_vif.rst_n);
          wait_reset();
        end
        begin
          seq_item_port.get_next_item(req); //get item from sequencer
          drive_trans(req);
          seq_item_port.item_done();
        end
      join_any
      disable fork;
    end
  endtask:run_phase


  //task that detects the reset and initializes the signals
  task wait_reset();
        @(posedge apb_vif.rst_n);

        `uvm_info(get_type_name(), "Reset detected by APB Driver", UVM_LOW);

        apb_vif.m_cb.paddr   <=  'h0;
        apb_vif.m_cb.psel    <= 1'b0;
        apb_vif.m_cb.penable <= 1'b0;
        apb_vif.m_cb.pwrite  <= 1'b0;
        apb_vif.m_cb.pwdata  <=  'h0;
  endtask:wait_reset

  //drive APB transaction
  task drive_trans(apb_trans  trans);
		`uvm_info(get_type_name(), $sformatf("APB MASTER Driver start a transfer:\n%s",trans.sprint()), UVM_LOW)
    	repeat (trans.trans_delay) @(apb_vif.m_cb);
		`uvm_info(get_type_name(), "APB MASTER AFTER DELAY\n\n", UVM_LOW)
        
        // Setup phase
	    apb_vif.m_cb.paddr <= trans.addr;
	    apb_vif.m_cb.psel <= 1'b1;
	    apb_vif.m_cb.penable <= 1'b0;
	    apb_vif.m_cb.pwrite <= (trans.access == APB_WRITE) ? 1'b1 : 1'b0;
	    
        if (trans.access == APB_WRITE) 
            apb_vif.m_cb.pwdata <= trans.data;
	    
        // Access phase
	    @(apb_vif.m_cb);
	    @(posedge apb_vif.clk);
	    apb_vif.m_cb.penable   <= 1'b1;
	    @(posedge apb_vif.clk);
	    @(apb_vif.m_cb);

        // Wait for pready
      
	    while (apb_vif.m_cb.pready === 1'b0) 
	      @(apb_vif.m_cb);

	    apb_vif.m_cb.psel <= 1'b0;
	    apb_vif.m_cb.penable <= 1'b0;
       
      `uvm_info(get_type_name(), $sformatf("APB MASTER Driver end trasfer"), UVM_LOW)
	 		
  endtask: drive_trans


endclass:apb_driver

`endif
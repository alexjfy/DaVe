`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import apb_pkg::*;

class apb_monitor extends uvm_monitor;

  uvm_analysis_port #(apb_trans) apb_port;
  virtual apb_interface#(`APB_AW, `APB_DW) apb_vif;

  apb_trans apb_trans;
  
  // Local variables
  int unsigned transfer_number;     // number of transfers collected
  int unsigned trans_delay;         // delay between last pready (ack) and next psel

  `uvm_component_utils(apb_monitor)


  function new(string name, uvm_component parent);
    super.new(name,parent);
    apb_port = new("apb_port", this);
  endfunction:new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_interface#(`APB_AW, `APB_DW))::get(this,"","apb_vif", apb_vif)) begin
      `uvm_fatal(get_type_name(), {"Virtual interface must be set for: ",get_full_name(),".apb_vif"})       
    end
  endfunction:build_phase

  task run_phase(uvm_phase phase);
    //Wait for the initial reset to pass
    @(negedge apb_vif.rst_n);
    @(posedge apb_vif.rst_n);

    //wait one more clock cycle after the initial reset
    @(apb_vif.mon_cb);
    fork
      collect_and_send();
    join_none
  endtask:run_phase

  task collect_and_send();
    forever begin
      fork

        //task that collects the transactions
        begin
          collect_transactions();
        end

        // task that counts the delay
        begin
          delay_counter();
        end

        // task that detects reset
        begin
          @(negedge apb_vif.rst_n);
          `uvm_info(get_type_name(), $sformatf("APB monitor detected reset"), UVM_MEDIUM)
          @(posedge apb_vif.rst_n);
        end
      join_any
      disable fork;
    end
  endtask:collect_and_send

  // Task for measuring the delay
  task delay_counter;
    forever begin
      trans_delay = 0;
      // count transaction delay
      while(!apb_vif.mon_cb.psel) begin
        @(apb_vif.mon_cb);
        trans_delay++;
      end
      @(negedge apb_vif.mon_cb.penable);
    end
  endtask:delay_counter
  
  task collect_transactions();
    forever begin
      apb_trans = new();
      // Wait for psel, penable and pready
      @(apb_vif.mon_cb iff (apb_vif.mon_cb.psel & apb_vif.mon_cb.penable & apb_vif.mon_cb.pready) === 1'b1);
      `uvm_info(get_type_name(), $sformatf("APB Monitor has started to collect a transfer"), UVM_LOW)
      apb_trans.addr = apb_vif.mon_cb.paddr;
      apb_trans.access = (apb_vif.mon_cb.pwrite == 1'b1) ? APB_WRITE : APB_READ;
      apb_trans.data = (apb_trans.access == APB_WRITE) ? apb_vif.mon_cb.pwdata : apb_vif.mon_cb.prdata;
      apb_trans.slv_error = apb_vif.mon_cb.pslverr;

      apb_trans.trans_delay = trans_delay;

      transfer_number++;
      
      // send collected trans to port 
      apb_port.write(apb_trans);
      `uvm_info(get_type_name(), $sformatf("APB Monitor has collected the following transfer:\n%s",apb_trans.sprint()), UVM_LOW)
      @(apb_vif.mon_cb);
    end
  endtask: collect_transactions

  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("APB Monitor has collected %0d transfers",transfer_number), UVM_LOW)
  endfunction

endclass:apb_monitor

`endif

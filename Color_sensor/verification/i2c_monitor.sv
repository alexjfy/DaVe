`ifndef I2C_MONITOR_SV
`define I2C_MONITOR_SV

  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import i2c_pkg::*;
class i2c_monitor extends uvm_monitor;

  uvm_analysis_port #(i2c_trans) i2c_port;
  virtual i2c_interface i2c_vif; 

  protected i2c_trans i2c_trans;

  // Local variables
  int unsigned transfer_number;     // number of transfers collected
  bit [7:0] data;                   // read data

  `uvm_component_utils_begin(i2c_monitor)
    `uvm_field_int(transfer_number, UVM_ALL_ON)
  `uvm_component_utils_end

  function new(string name, uvm_component parent);
    super.new(name,parent);
    i2c_port = new("i2c_port", this);
  endfunction:new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual i2c_interface)::get(this,"","i2c_vif", i2c_vif)) begin
      `uvm_fatal(get_type_name(), {"Virtual interface must be set for: ",get_full_name(),".i2c_vif"})       
    end
  endfunction:build_phase

  task run_phase(uvm_phase phase);
    @(negedge i2c_vif.rst_n);
    @(posedge i2c_vif.rst_n);
    @(i2c_vif.mon_cb);
    fork
      collect_and_send();
    join_none
  endtask:run_phase

  task collect_and_send();
    forever begin
      fork
        collect_transactions();
        // detect reset
        begin
          @(negedge i2c_vif.rst_n);
          `uvm_info(get_type_name(), $sformatf("I2C monitor reset"), UVM_MEDIUM)
          @(posedge i2c_vif.rst_n);
        end
      join_any
      disable fork;
    end
  endtask:collect_and_send
  
  task collect_transactions();
    i2c_trans = new();
    // Wait for START
    @(negedge i2c_vif.mon_cb.sda iff i2c_vif.mon_cb.scl === 'b1);
    `uvm_info(get_type_name(), $sformatf("I2C Monitor has started to collect a transfer"), UVM_LOW)
    // read address
    repeat(`I2C_AW) begin
      @(posedge i2c_vif.mon_cb.scl);
      i2c_trans.addr <<= 1;
      i2c_trans.addr[0] = i2c_vif.mon_cb.sda;
    end 
    @(posedge i2c_vif.mon_cb.scl);
    // read access kind
    i2c_trans.access = (i2c_vif.mon_cb.sda === 'b0) ? I2C_WRITE : I2C_READ;
    @(posedge i2c_vif.mon_cb.scl);
    // read address response
    i2c_trans.addr_resp = (i2c_vif.mon_cb.sda === 'b0) ? ACK : NACK;
    i2c_trans.data_resp = NACK;
    fork
      // read data
      forever begin
        repeat(`I2C_DW) begin
          @(posedge i2c_vif.mon_cb.scl);
          data <<= 1;
          data[0] = i2c_vif.mon_cb.sda;
        end
        i2c_trans.data.push_back(data);
        i2c_trans.nr_words++;
        `uvm_info(get_type_name(), $sformatf("I2C Monitor nr_words %0d", i2c_trans.nr_words), UVM_HIGH)
        @(posedge i2c_vif.mon_cb.scl);
        // read data response
        i2c_trans.data_resp = (i2c_vif.mon_cb.sda === 'b0) ? ACK : NACK;
      end
      // wait for STOP
      begin
        @(posedge i2c_vif.mon_cb.sda iff i2c_vif.mon_cb.scl === 'b1);
        `uvm_info(get_type_name(), $sformatf("STOP"), UVM_MEDIUM)
      end
    join_any
    disable fork;
    transfer_number++;

    // send collected trans to port 
    i2c_port.write(i2c_trans);
    `uvm_info(get_type_name(), $sformatf("I2C Monitor has collected the following transfer:\n%s",i2c_trans.sprint()), UVM_LOW)
    @(i2c_vif.mon_cb);
  endtask: collect_transactions

  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("I2C Monitor has collected %0d transfers",transfer_number), UVM_LOW)
  endfunction

endclass:i2c_monitor

`endif
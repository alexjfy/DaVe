`ifndef I2C_DRIVER_SV
`define I2C_DRIVER_SV

class i2c_driver extends uvm_driver;

  bit [`I2C_AW-1:0] address;

  `uvm_component_utils_begin(i2c_driver)
    `uvm_field_int(address, UVM_ALL_ON)
  `uvm_component_utils_end

  virtual i2c_interface i2c_vif;  

  function new(string name,uvm_component parent = null);
    super.new(name,parent);
  endfunction:new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db#(virtual i2c_interface)::get(this,"","i2c_vif", i2c_vif)) 
      `uvm_fatal(get_type_name(), {"Virtual interface must be set for: ",get_full_name(),".i2c_vif"})
  endfunction:build_phase

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    drive_reset_values();
    // initial reset
    @(negedge i2c_vif.rst_n);
    @(posedge i2c_vif.rst_n);
    `uvm_info(get_type_name(), $sformatf("I2C driver after reset"), UVM_MEDIUM)
    fork
      drive();
    join
  endtask:run_phase

  //idle values for driven signals
  task drive_reset_values();
    i2c_vif.s_cb.sda_drive  <= 'b1;
  endtask:drive_reset_values

  task drive();
    forever begin
      fork
        begin
          wait(i2c_vif.rst_n === 'b1);
          drive_trans();
        end
        // detect reset
        begin
          @(negedge i2c_vif.rst_n);
          drive_reset_values();
          @(posedge i2c_vif.rst_n);
        end
      join_any
      disable fork;
    end
  endtask:drive

  // drive I2C transaction
  task drive_trans();
    bit [`I2C_AW-1:0] rx_addr;
    bit access_kind;
    // wait for START
    `uvm_info(get_type_name(), $sformatf("I2C SLAVE"), UVM_MEDIUM)
    @(negedge i2c_vif.mon_cb.sda iff i2c_vif.mon_cb.scl === 'b1);
    // read address
    repeat(`I2C_AW) begin
      @(posedge i2c_vif.s_cb.scl);
      rx_addr <<= 1;
      rx_addr[0] = i2c_vif.s_cb.sda;
    end 
    @(posedge i2c_vif.s_cb.scl);
    // receive access kind
    access_kind = i2c_vif.s_cb.sda;
    // don't ACK if not a write
    @(negedge i2c_vif.s_cb.scl);
    // send ACK if received address = agent address and access kind = WRITE, else send NACK
    `uvm_info(get_type_name(), $sformatf("agent address: %h\nreceived address: %h\naccess kind: %b", address, rx_addr, access_kind), UVM_MEDIUM)
    i2c_vif.s_cb.sda_drive <= ((rx_addr == address) & (access_kind == I2C_WRITE)) ? 'b0 : 'b1;
    `uvm_info(get_type_name(), $sformatf("addr response"), UVM_HIGH)
    @(negedge i2c_vif.s_cb.scl);
    i2c_vif.s_cb.sda_drive <= 'b1;
    `uvm_info(get_type_name(), $sformatf("release"), UVM_HIGH)
    fork
      // rx data
      if(rx_addr == address)
        forever begin
          // receive data and send ACK
          repeat(`I2C_DW) @(posedge i2c_vif.s_cb.scl);
          @(negedge i2c_vif.s_cb.scl);
          i2c_vif.s_cb.sda_drive <= 'b0;
          fork
            @(negedge i2c_vif.s_cb.scl);
            begin
              @(posedge i2c_vif.s_cb.scl);
              repeat(20) @(i2c_vif.s_cb);
            end
          join_any
          disable fork;
          i2c_vif.s_cb.sda_drive <= 'b1;
          `uvm_info(get_type_name(), $sformatf("ACK"), UVM_HIGH)
        end
      else forever @(i2c_vif.s_cb);
      // wait for STOP
      begin
        @(posedge i2c_vif.s_cb.sda iff i2c_vif.s_cb.scl === 'b1);
        `uvm_info(get_type_name(), $sformatf("STOP"), UVM_MEDIUM)
      end
    join_any
    disable fork;
  endtask

endclass

`endif
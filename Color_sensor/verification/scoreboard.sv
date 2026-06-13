`ifndef __scoreboard
`define __scoreboard

`include "uvm_macros.svh"

// `include "../apb_uvc/apb_trans.sv"
// `include "../i2c_uvc/i2c_trans.sv"
`include "coverage_scoreboard.sv"

import uvm_pkg::*;
import apb_pkg::*;
import i2c_pkg::*;

`uvm_analysis_imp_decl(_apb) // apb
`uvm_analysis_imp_decl(_i2c) // i2c

class scoreboard extends uvm_scoreboard;
  
  `uvm_component_utils(scoreboard)
  
  uvm_analysis_imp_apb #(apb_trans, scoreboard) apb_port;
  uvm_analysis_imp_i2c #(i2c_trans, scoreboard) i2c_port;

  // Transactions
  apb_trans apb_transaction;
  i2c_trans i2c_transaction;
  i2c_trans predicted_output;

  bit enable;
  integer i;

  coverage_scoreboard coverage_collector;

// DUT register shadows
logic [15:0] reg_config     ; // address #00
logic [15:0] reg_clear_ch   ; // address #02
logic [15:0] reg_red_ch     ; // address #04
logic [15:0] reg_green_ch   ; // address #06
logic [15:0] reg_blue_ch    ; // address #08
logic [15:0] reg_infrared_ch; // address #0C
logic [15:0] reg_seed       ; // address #10
logic [15:0] reg_status     ; // address #12

function new(string name="scoreboard", uvm_component parent=null); // Scoreboard constructor
    super.new(name, parent);

    apb_port = new("apb_port", this);
    i2c_port = new("i2c_port", this);

    apb_transaction = new();
    i2c_transaction = new();

    // Initialize register shadows to DUT reset values
    reg_config      = 16'h0001;  // SD=1 (shutdown mode)
    reg_clear_ch    = 16'h0;
    reg_red_ch      = 16'h0;
    reg_green_ch    = 16'h0;
    reg_blue_ch     = 16'h0;
    reg_infrared_ch = 16'h0;
    reg_seed        = 16'hACE1;  // default seed
    reg_status      = 16'h0;
endfunction
  
virtual function void connect_phase (uvm_phase phase); // Environment Connect
    super.connect_phase(phase);
    //coverage_collector.p_scoreboard = this; // Coverage Collector Connect
endfunction
  
virtual function void build_phase(uvm_phase phase); // Environment Build
    super.build_phase(phase);
endfunction

// WRITE APB
function void write_apb(input apb_trans new_apb_transaction);
    `uvm_info("SCOREBOARD", $sformatf("Received an APB transaction:\n"), UVM_LOW)
    new_apb_transaction.sprint(); // print?

    $display($sformatf("When APB data was received, enable was %d", enable));

    // Skip verification for transactions where DUT reported slave error
    if (new_apb_transaction.slv_error) return;

// Store and verify DUT registers
if (new_apb_transaction.access == APB_WRITE) begin
case (new_apb_transaction.addr)
    5'h00 : begin
        reg_config      <= new_apb_transaction.data;
        reg_status[0]   <= ~reg_config[0];
    end
    5'h10 : reg_seed <= new_apb_transaction.data;
    5'h02, 5'h04, 5'h06, 5'h08, 5'h0C, 5'h12 : ; // Read-only registers - writes silently ignored by DUT
    default: `uvm_warning(get_full_name(), "Invalid address at write transaction")
endcase


   // coverage_collector.config_register.sample(); // Verif Config Register Coverage
end else
case (new_apb_transaction.addr)
    5'h00 : assert( reg_config      == new_apb_transaction.data );
    5'h02 : assert( reg_clear_ch    == new_apb_transaction.data );
    5'h04 : assert( reg_red_ch      == new_apb_transaction.data );
    5'h06 : assert( reg_green_ch    == new_apb_transaction.data );
    5'h08 : assert( reg_blue_ch     == new_apb_transaction.data );
    5'h0C : assert( reg_infrared_ch == new_apb_transaction.data );
    5'h10 : assert( reg_seed        == new_apb_transaction.data );
    5'h12 : assert( reg_status      == new_apb_transaction.data );
    default: `uvm_warning(get_full_name(), "Invalid address at read transaction")
endcase
endfunction : write_apb

// WRITE I2C
function void write_i2c(input i2c_trans new_i2c_transaction);  
    `uvm_info("SCOREBOARD", $sformatf("Received an I2C transaction:\n"), UVM_LOW)
    new_i2c_transaction.sprint(); // print?

    // Write registers with I2C colour data
    reg_red_ch      = new_i2c_transaction.data[0];
    reg_green_ch    = new_i2c_transaction.data[1];
    reg_blue_ch     = new_i2c_transaction.data[2];
    reg_clear_ch    = new_i2c_transaction.data[3];
    reg_infrared_ch = new_i2c_transaction.data[4];
    $display($sformatf("When I2C data was received, enable was %d", enable));

   // coverage_collector.config_register.sample(); // Verif Config Register Coverage
    
    // Verif predicted and actual data
    assert ( new_i2c_transaction.addr     == reg_config[13:7]); // Verif Addr
    assert ( new_i2c_transaction.nr_words == 10              ); // Verif Nr Words (5 channels x 2 bytes)
    assert ( new_i2c_transaction.access   == I2C_WRITE       ); // Verif Access (always WRITE)

    if (new_i2c_transaction.addr_resp == NACK || new_i2c_transaction.data_resp == NACK)
    reg_status[2] <= 1'b1; else
    reg_status[2] <= 1'b0;
endfunction : write_i2c

endclass
`endif

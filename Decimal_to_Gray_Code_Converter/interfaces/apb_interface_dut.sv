`ifndef __apb_intf
`define __apb_intf

`timescale 1ns/1ns

interface apb_interface_dut;
  logic        pclk;
  logic        rst_n;
  logic [2:0]  paddr;
  logic        psel;
  logic        penable;
  logic [7:0]  pwdata;
  logic        pwrite;
  logic [7:0]  prdata;
  logic        pready;
  logic        pslverr;

  import uvm_pkg::*;

  logic rst_n_seen_low;
  logic rst_n_was_applied;

  initial begin
    rst_n_seen_low = 1'b0;
    rst_n_was_applied = 1'b0;
  end

  // Detect when rst_n has been low at least once
  always @(negedge rst_n) begin
    rst_n_seen_low <= 1'b1;
  end

  // Detect when rst_n returns to 1 AFTER being low
  always @(posedge pclk) begin
    if (rst_n_seen_low && rst_n === 1'b1)
      rst_n_was_applied <= 1'b1;
    if (rst_n === 1'b0)
      rst_n_was_applied <= 1'b0;  // if we re-enter reset
  end


  wire disable_assertions = !rst_n_was_applied;


  property pready_is_pulse_p;
    @(posedge pclk) disable iff (disable_assertions)
      pready |=> !pready;
  endproperty
  assert_pready_is_pulse: assert property (pready_is_pulse_p)
    else $display("[ASSERT-APB] FAIL: pready_is_pulse - pready is not a pulse at T=%0t", $time);

  property pready_fell_with_psel_p;
    @(posedge pclk) disable iff (disable_assertions)
      pready |-> $past(psel);
  endproperty
  assert_pready_fell_with_psel: assert property (pready_fell_with_psel_p)
    else $display("[ASSERT-APB] FAIL: pready_fell_with_psel - pready without psel at T=%0t", $time);

  property psel_before_penable_p;
    @(posedge pclk) disable iff (disable_assertions)
      penable |-> $past(psel);
  endproperty
  assert_psel_before_penable: assert property (psel_before_penable_p)
    else $display("[ASSERT-APB] FAIL: psel_before_penable - penable without psel at T=%0t", $time);

  property pwrite_stable_during_access_p;
    @(posedge pclk) disable iff (disable_assertions)
      (psel && penable) |-> ($stable(pwrite));
  endproperty
  assert_pwrite_during_transaction: assert property (pwrite_stable_during_access_p)
    else $display("[ASSERT-APB] FAIL: pwrite_during_transaction - pwrite changed in ACCESS at T=%0t", $time);

  property pready_not_unknown_p;
    @(posedge pclk) disable iff (disable_assertions)
      !$isunknown(pready);
  endproperty
  assert_pready_unknown: assert property (pready_not_unknown_p)
    else $display("[ASSERT-APB] FAIL: pready_unknown - pready is X/Z at T=%0t", $time);

  property pslverr_when_pready_p;
    @(posedge pclk) disable iff (disable_assertions)
      pslverr |-> pready;
  endproperty
  assert_pslverr_when_pready: assert property (pslverr_when_pready_p)
    else $display("[ASSERT-APB] FAIL: pslverr_when_pready - pslverr=1 without pready=1 at T=%0t", $time);

  property penable_single_cycle_p;
    @(posedge pclk) disable iff (disable_assertions)
      penable |=> !penable;
  endproperty
  assert_penable_single_cycle: assert property (penable_single_cycle_p)
    else $display("[ASSERT-APB] FAIL: penable_single_cycle - penable is not a pulse at T=%0t", $time);

  property paddr_stable_during_access_p;
    @(posedge pclk) disable iff (disable_assertions)
      (psel && penable) |-> ($stable(paddr));
  endproperty
  assert_paddr_stable: assert property (paddr_stable_during_access_p)
    else $display("[ASSERT-APB] FAIL: paddr_stable - paddr changed in ACCESS at T=%0t", $time);

endinterface


`endif

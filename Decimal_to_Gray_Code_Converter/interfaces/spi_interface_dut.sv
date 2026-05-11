`ifndef __spi_intf
`define __spi_intf

`timescale 1ns/1ns

interface spi_interface_dut;
  logic        sclk;
  logic        mosi;
  logic        miso;
  logic        cs;

  import uvm_pkg::*;

  // SPI assertions — protocol checks that run any time the sim is outside reset

  // (1) When CS is high (bus idle) the SCLK must not have any edges.
  //     Seeing a posedge sclk with cs=1 means the DUT broke protocol.
  property sclk_unmoved_on_idle_ss_p;
    @(posedge sclk)
      (cs == 1) |-> 0;  // if we reach posedge sclk with cs=1, it's an error
  endproperty
  assert_sclk_unmoved_on_idle_ss: assert property (sclk_unmoved_on_idle_ss_p)
    else $display("[ASSERT-SPI] FAIL: sclk_unmoved_on_idle_ss - SCLK active with CS=1 at T=%0t", $time);

  // (2) Clean CS release: when CS goes back to 1 sclk must already be 0.
  property cs_deassert_clean_p;
    @(posedge cs)
      (sclk == 0);
  endproperty
  assert_cs_deassert_clean: assert property (cs_deassert_clean_p)
    else $display("[ASSERT-SPI] FAIL: cs_deassert_clean - CS deactivated with SCLK!=0 at T=%0t", $time);

  // (3) MOSI can't be X/Z while a transfer is in progress (cs=0).
  property mosi_valid_during_transfer_p;
    @(posedge sclk)
      (cs == 0) |-> !$isunknown(mosi);
  endproperty
  assert_mosi_valid: assert property (mosi_valid_during_transfer_p)
    else $display("[ASSERT-SPI] FAIL: mosi_valid - MOSI is X/Z during transfer at T=%0t", $time);

endinterface


`endif

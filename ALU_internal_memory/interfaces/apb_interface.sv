// Module name: apb_interface
// HDL        : System Verilog
// Description: Bundles the APB signals between the testbench and the DUT and
//              exposes separate clocking blocks for the master (driver) and
//              the monitor.
interface apb_interface(
  input clk,
  input reset_n,
  input state
  );

 import uvm_pkg::*;
  wire                    psel    ;
  wire                    penable ; 
  wire     [15:0]         paddr   ;
  wire                    pwrite  ;
  wire     [31:0]         pwdata  ;
  wire                    pready  ;
  wire     [31:0]         prdata  ;
  wire                    pslverr ;

  clocking cb_master_apb @(posedge clk);
    output       psel    ;
    output       penable ; 
    output       paddr   ;
    output       pwrite  ;
    output       pwdata  ;
    input        pready  ;
    input        prdata  ;
    input        pslverr ;
  endclocking 

  clocking cb_monitor_apb @(posedge clk);
    input   psel    ;
    input   penable ; 
    input   paddr   ;
    input   pwrite  ;
    input   pwdata  ;
    input   pready  ;
    input   prdata  ;
    input   pslverr ;
  endclocking 

endinterface
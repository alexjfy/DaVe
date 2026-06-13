// Module name: reset_interface
// HDL        : System Verilog
// Description: Carries the active-low reset and the DUT run/freeze state bit.
//              Both are driven by the reset agent and observed by the reset
//              monitor.
interface reset_interface(
  input clk
  );

  import uvm_pkg::*;
  
  bit reset_n;
  bit state;
endinterface
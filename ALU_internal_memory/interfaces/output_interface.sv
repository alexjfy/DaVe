// Module name: output_interface
// HDL        : System Verilog
// Description: Passive observation of the ALU result bus plus the APB control
//              signals used by the output monitor to time its sampling.
interface output_interface(
  input clk,
  input reset_n,
  input state
  );

  import uvm_pkg::*;
  wire     [8:0]         result   ;
  wire psel;
  wire penable;
  wire pwrite;
  wire pready;

  clocking cb_master_output @(posedge clk);
  input result;
  input psel;
  input penable;
  input pwrite;
  input pready;
  endclocking

endinterface
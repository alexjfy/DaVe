`ifndef __lamp_intf
`define __lamp_intf

interface lamp_interface;

  logic clk; 
  logic rst;
  logic [1:0] light_level;
  
endinterface

`endif
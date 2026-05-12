//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
interface output_interface(input logic clk,reset);
  
  //declaring the signals
  logic  flame_on;
  
  
  
  //clocking block signals are synchronized to the rising clock edge
 
  
  //monitor clocking block
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    input flame_on;
   
     
  endclocking
  
  
  
  //monitor modport  
  modport MONITOR (clocking monitor_cb,input clk,reset);
  
endinterface
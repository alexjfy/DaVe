//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
interface buttons_interface(input logic clk,reset);
  
  //declaring the signals
  logic button_mod_econ;
  logic button_mod_comf;
  logic button_mod_thermo;
  logic button_child_prot;
  
  
  //clocking block signals are synchronous with the rising clock edge
  //driver clocking block
  clocking driver_cb @(posedge clk);
    //input signals are sampled one time unit before the clock edge, and output signals are driven one time unit after the clock edge; this eliminates simultaneous read/write conflicts
    default input #1 output #1;
    output button_mod_econ;
    output button_mod_comf;
    output button_mod_thermo;
    output button_child_prot;
     
  endclocking
  
  //monitor clocking block
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    
    input button_mod_econ;
    input button_mod_comf;
    input button_mod_thermo;
    input button_child_prot;
       
  endclocking
  
  //driver modport
  modport DRIVER  (clocking driver_cb,input clk,reset);
  
  //monitor modport  
  modport MONITOR (clocking monitor_cb,input clk,reset);
  
endinterface
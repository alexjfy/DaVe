//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
interface apb_interface(input logic clk,reset);
  
  //declaring the signals
  logic [ADDR_WIDTH-1 :0] paddr;
  logic pwrite;
  logic psel;
  logic penable;
  logic [DATA_WIDTH-1 :0] pwdata;
  logic pready;
  logic pslverr;
  logic [DATA_WIDTH-1 :0] prdata;
  
  //clocking block signals are synchronized to the rising clock edge
  //driver clocking block
  clocking driver_cb @(posedge clk);
    //input signals are sampled one time unit before the clock edge, and output signals are driven one time unit after the clock edge; this prevents simultaneous read/write conflicts
    default input #1 output #1;
    output paddr;
    output pwrite;
    output psel;
    output penable;
    output pwdata;
    input pready;
    input pslverr;
    input  prdata;  
  endclocking
  
  //monitor clocking block
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    input paddr;
    input pwrite;
    input psel;
    input penable;
    input pwdata;
    input pready;
    input pslverr;
    input prdata;
  endclocking
  
  //driver modport
  modport DRIVER  (clocking driver_cb,input clk,reset);
  
  //monitor modport  
  modport MONITOR (clocking monitor_cb,input clk,reset);
  
endinterface
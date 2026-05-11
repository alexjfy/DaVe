interface irq_interface(input logic clk, reset);

  //declaring the signals
  logic irq;

  //Clocking block signals are synchronous with the rising clock edge
  //monitor clocking block
  clocking monitor_cb @(posedge clk);
  //Input signals are sampled one time unit before the clock edge,
   // and output signals are driven one time unit after the clock edge;
   // this eliminates race conditions between simultaneous reads and writes
    default input #1 output #1;
    input irq;
  endclocking

  //monitor modport 
  modport MONITOR(clocking monitor_cb, input clk, reset);

endinterface : irq_interface
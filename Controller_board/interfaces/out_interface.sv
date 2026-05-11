interface out_interface(
    input logic clk,
    input logic reset
);

  // Output signal declarations
  	logic wipers;
    logic high_beam;
    logic washer;
    logic flash;
    logic right_signal;
    logic left_signal;



  // Clocking block for monitor
  clocking monitor_cb @(posedge clk);
    // Synchronous with the positive edge of the clock
    default input #1 output #1;
    input wipers;
    input high_beam;
    input washer;
    input flash;
    input right_signal;
    input left_signal;
  endclocking


  // Monitor modport
  modport MONITOR (clocking monitor_cb, input clk, reset);

endinterface

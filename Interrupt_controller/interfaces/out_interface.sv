interface out_interface(input logic clk,reset);

  //declaring the signals
  logic [2:0] irq; //binary code of the active interrupt. E.g., if interrupt 2 is active, irq will have binary value 010.
  logic irq_flag; //a pulse signal indicating that irq is valid. Active for only one clock cycle, confirming that the interrupt identified by irq is valid and should be served.

  //monitor clocking block. Synchronizes signal sampling with the clock (clk).
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    input irq;
    input irq_flag;
  endclocking

   //monitor modport. The monitor uses the MONITOR modport to sample signals on each clock cycle.
  modport MONITOR (clocking monitor_cb,input clk,reset);

   property IRQ_FLAG_PULSE;
     @(posedge clk) disable iff (!reset)
      irq_flag |=> !irq_flag;
   endproperty

    assert property (IRQ_FLAG_PULSE);

endinterface
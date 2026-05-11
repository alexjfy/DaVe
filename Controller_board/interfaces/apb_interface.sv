interface apb_interface(
    input logic clk,
    input logic reset
);

  // Signal declarations from Driver and Slave (DUT)
  logic [ADDR_WIDTH-1:0] paddr;
  logic pwrite;
  logic [DATA_WIDTH-1:0] pwdata;
  logic [DATA_WIDTH-1:0] prdata;
  logic penable;
  logic pready;
  logic pslverr;
  logic psel;

  // Clocking block for driver
  clocking driver_cb @(posedge clk);
    // Synchronous with the positive edge of the clock
    default input #1 output #1;
    output   paddr;
    output   pwrite;
    output   pwdata;
    input    prdata;
    output   penable;
    input    pready;
    input    pslverr;
    output   psel;
  endclocking

  // Clocking block for monitor
  clocking monitor_cb @(posedge clk);
    // Synchronous with the positive edge of the clock
    default input #1 output #1;
    input  paddr;
    input  pwrite;
    input  pwdata;
    input  prdata;
    input  penable;
    input  pready;
    input  pslverr;
    input  psel;
  endclocking

  // Driver modport
  modport DRIVER (clocking driver_cb, input clk, reset);

  // Monitor modport
  modport MONITOR (clocking monitor_cb, input clk, reset);

     property psel_and_penable_active;
        @(posedge clk) disable iff(reset)
        $rose(psel) |-> ##1 $rose(penable);
      endproperty
        assert property (psel_and_penable_active);

       property pready_after_psel_falls;
         @(posedge clk) disable iff(reset)
         $fell(psel) |-> $fell(pready);
       endproperty
          assert property (pready_after_psel_falls);

       property penable_after_psel_falls;
         @(posedge clk) disable iff(reset)
         $fell(psel) |-> $fell(penable);
       endproperty
            assert property (penable_after_psel_falls);

       property pwdata_activate_at_psel_and_pwrite;
         @(posedge clk) disable iff(reset)
         psel && pwrite &&penable |-> $stable(pwdata);
       endproperty
            assert property (pwdata_activate_at_psel_and_pwrite);

endinterface

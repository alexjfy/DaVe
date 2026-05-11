interface apb_interface(input logic clk, reset);

  //declaring the signals
  logic         psel;
  logic         penable;
  logic [4:0]   paddr;
  logic         pwrite;
  logic [31:0]  pwdata;
  logic [31:0]  prdata;
  logic         pready;
  logic         pslverr;

  //Clocking block signals are synchronous with the rising clock edge
  //driver clocking block
  clocking driver_cb @(posedge clk);
   //Input signals are sampled one time unit before the clock edge,
   // and output signals are driven one time unit after the clock edge;
   // this eliminates race conditions between simultaneous reads and writes
    default input #1 output #1;
    input pready;
    input prdata;
    input pslverr;
    output psel;
    output penable;
    output paddr;
    output pwrite;
    output pwdata;
  endclocking 

  //monitor clocking block
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    input psel;
    input penable;
    input paddr;
    input pwrite;
    input pwdata;
    input prdata;
    input pready;
    input pslverr;
  endclocking

  //driver modport
  modport DRIVER (clocking driver_cb, input clk, reset);

  //monitor modport
  modport MONITOR(clocking monitor_cb, input clk, reset);



  property penable_signal_p;
    disable iff(~reset)
    @(posedge clk) psel |-> !$isunknown(penable);
  endproperty : penable_signal_p
  penable_signal_chk : assert property (penable_signal_p)
    else $warning("T=%0t [ASSERT] penable is unknown during transaction!", $time);

  property paddr_signal_p;
    disable iff(~reset)
    @(posedge clk) psel |-> !$isunknown(paddr);
  endproperty : paddr_signal_p
  paddr_signal_chk : assert property (paddr_signal_p)
    else $warning("T=%0t [ASSERT] paddr is unknown during transaction!", $time);

  property pwrite_signal_p;
    disable iff(~reset)
    @(posedge clk) psel |-> !$isunknown(pwrite);
  endproperty : pwrite_signal_p
  pwrite_signal_chk : assert property (pwrite_signal_p)
    else $warning("T=%0t [ASSERT] pwrite is unknown during transaction!", $time);

  property pready_signal_p;
    disable iff(~reset)
    @(posedge clk) psel |-> !$isunknown(pready);
  endproperty : pready_signal_p
  pready_signal_chk : assert property (pready_signal_p)
    else $warning("T=%0t [ASSERT] pready is unknown during transaction!", $time);

  property pslverr_signal_p;
    disable iff(~reset)
    @(posedge clk) psel |-> !$isunknown(pslverr);
  endproperty : pslverr_signal_p
  pslverr_signal_chk : assert property (pslverr_signal_p)
    else $warning("T=%0t [ASSERT] pslverr is unknown during transaction!", $time);

  property pwdata_signal_p;
    disable iff(~reset)
    @(posedge clk) (psel && pwrite) |-> !$isunknown(pwdata);
  endproperty : pwdata_signal_p
  pwdata_signal_chk : assert property (pwdata_signal_p)
    else $warning("T=%0t [ASSERT] pwdata is unknown during write transaction!", $time);

  // pready must assert within 100 cycles after penable
  property pready_p;
    disable iff(~reset)
    @(posedge clk) penable |-> ##[0:100] pready;
  endproperty : pready_p
  pready_chk : assert property (pready_p)
    else $error("T=%0t [ASSERT] pready timeout! No response within 100 cycles.", $time);

  // pslverr must only assert when pready is also asserted
  property pslverr_pready_sync_p;
    disable iff(~reset)
    @(posedge clk) pslverr |-> pready;
  endproperty : pslverr_pready_sync_p
  pslverr_pready_sync_chk : assert property (pslverr_pready_sync_p)
    else $error("T=%0t [ASSERT] pslverr asserted without pready!", $time);

  // penable must not be high at the same time psel rises
  property concurrent_penable_psel_p;
    disable iff(~reset)
    @(posedge clk) $rose(psel) |-> ~penable;
  endproperty : concurrent_penable_psel_p
  concurrent_penable_psel_chk : assert property (concurrent_penable_psel_p)
    else $error("T=%0t [ASSERT] penable asserted simultaneously with psel!", $time);

  // pready must not be high at the same time psel rises
  property concurrent_pready_psel_p;
    disable iff(~reset)
    @(posedge clk) $rose(psel) |-> ~pready;
  endproperty : concurrent_pready_psel_p
  concurrent_pready_psel_chk : assert property (concurrent_pready_psel_p)
    else $error("T=%0t [ASSERT] pready asserted simultaneously with psel!", $time);

  // paddr must remain stable during a transaction
  property paddr_stable_p;
    disable iff(~reset)
    @(posedge clk) (psel && !penable) |=> $stable(paddr);
  endproperty : paddr_stable_p
  paddr_stable_chk : assert property (paddr_stable_p)
    else $error("T=%0t [ASSERT] paddr changed during transaction!", $time);

  // pwrite must remain stable during a transaction
  property pwrite_stable_p;
    disable iff(~reset)
    @(posedge clk) (psel && !penable) |=> $stable(pwrite);
  endproperty : pwrite_stable_p
  pwrite_stable_chk : assert property (pwrite_stable_p)
    else $error("T=%0t [ASSERT] pwrite changed during transaction!", $time);

  // pwdata must remain stable during a write transaction
  property pwdata_stable_p;
    disable iff(~reset)
    @(posedge clk) (psel && pwrite && !penable) |=> $stable(pwdata);
  endproperty : pwdata_stable_p
  pwdata_stable_chk : assert property (pwdata_stable_p)
    else $error("T=%0t [ASSERT] pwdata changed during write transaction!", $time);

  // penable must rise one cycle after psel rises
  property penable_p;
    disable iff(~reset)
    @(posedge clk) $rose(psel) |=> $rose(penable);
  endproperty : penable_p
  penable_chk : assert property (penable_p)
    else $error("T=%0t [ASSERT] penable did not rise after psel!", $time);

endinterface : apb_interface
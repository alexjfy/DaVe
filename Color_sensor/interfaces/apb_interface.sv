`ifndef APB_INTERFACE_SV
`define APB_INTERFACE_SV

interface apb_interface #(APB_AW=32,APB_DW=32) (input clk, input rst_n);

  // Signals
  wire [APB_AW-1:0] paddr   ; // address bus
  wire              psel    ; // select 
  wire              penable ; // enable
  wire              pwrite  ; // write/read selector
  wire [APB_DW-1:0] pwdata  ; // data from Master
  wire [APB_DW-1:0] prdata  ; // data from Slave
  wire              pready  ; // acknowledge
  wire              pslverr ; // error
  
  
  reg stable_assertion_enable;
  reg post_reset = 0;

  initial begin
    @(negedge rst_n);
    @(posedge rst_n);
    @(posedge clk);
    post_reset = 1;
  end

  // Clocking blocks
  // Driver
  clocking m_cb @(posedge clk);
    output paddr   ; 
    output psel    ;
    output penable ;
    output pwrite  ; 
    output pwdata  ;
    input  prdata  ;
    input  pready  ; 
    input  pslverr ;
  endclocking: m_cb

  // Monitor
  clocking mon_cb @(posedge clk);
    input paddr   ;
    input psel    ;
    input penable ;
    input pwrite  ; 
    input pwdata  ;
    input prdata  ;
    input pready  ; 
    input pslverr ;
  endclocking: mon_cb

// Keep stable_assertion_enable HIGH from penable until pready
  initial forever begin
    @(posedge penable);
    @(negedge clk);
    stable_assertion_enable = 1'b1;
    wait(pready === 1'b1);
    stable_assertion_enable = 1'b0;
    @(posedge clk);
  end
  
  // Assertions
  // Signals are never X or Z (disabled before first reset completes)
  assert property (@(posedge clk) disable iff (!rst_n || !post_reset) !$isunknown(paddr))
    else $error("APB Interface: !!! paddr is unknown !!!");
  assert property (@(posedge clk) disable iff (!rst_n || !post_reset) !$isunknown(psel))
    else $error("APB Interface: !!! psel is unknown !!!");
  assert property (@(posedge clk) disable iff (!rst_n || !post_reset) !$isunknown(penable))
    else $error("APB Interface: !!! penable is unknown !!!");
  assert property (@(posedge clk) disable iff (!rst_n || !post_reset) !$isunknown(pwrite))
    else $error("APB Interface: !!! pwrite is unknown !!!");
  assert property (@(posedge clk) disable iff (!rst_n || !post_reset) !$isunknown(pwdata))
    else $error("APB Interface: !!! pwdata is unknown !!!");
  assert property (@(posedge clk) disable iff (!rst_n || !post_reset) !$isunknown(prdata))
    else $error("APB Interface: !!! prdata is unknown !!!");
  assert property (@(posedge clk) disable iff (!rst_n || !post_reset) !$isunknown(pready))
    else $error("APB Interface: !!! pready is unknown !!!");
  assert property (@(posedge clk) disable iff (!rst_n || !post_reset) !$isunknown(pslverr))
    else $error("APB Interface: !!! pslverr is unknown !!!");

  // Signals don't change before pready
  assert property (@(clk) disable iff (!rst_n || !post_reset) stable_assertion_enable |-> $stable(paddr))
    else $error("APB Interface: !!! paddr changed before pready !!!");
  assert property (@(clk) disable iff (!rst_n || !post_reset) stable_assertion_enable |-> $stable(psel))
    else $error("APB Interface: !!! psel changed before pready !!!");
  assert property (@(clk) disable iff (!rst_n || !post_reset) stable_assertion_enable |-> $stable(penable))
    else $error("APB Interface: !!! penable changed before pready !!!");
  assert property (@(clk) disable iff (!rst_n || !post_reset) stable_assertion_enable |-> $stable(pwrite))
    else $error("APB Interface: !!! pwrite changed before pready !!!");
  assert property (@(clk) disable iff (!rst_n || !post_reset) stable_assertion_enable |-> $stable(prdata))
    else $error("APB Interface: !!! prdata changed before pready !!!");
  assert property (@(clk) disable iff (!rst_n || !post_reset) stable_assertion_enable |-> $stable(pwdata))
    else $error("APB Interface: !!! pwdata changed before pready !!!");
  assert property (@(clk) disable iff (!rst_n || !post_reset) stable_assertion_enable |-> $stable(pslverr))
    else $error("APB Interface: !!! pslverr changed before pready !!!");

  // penable doesn't come without psel
  assert property (@(posedge clk) disable iff (!rst_n) penable |-> psel)
    else $error("APB Interface: !!! penable came without psel !!!");


endinterface:apb_interface

`endif
interface apb_interface(input logic clk,reset);

  //declaring the signals
  logic [5:0] paddr;
  logic penable;
  logic psel;
  logic pwrite;
  logic pready;
  logic pslverr;
  logic [31:0] pwdata;
  logic [31:0] prdata;

   //signals in the clocking block are synchronous with the rising clock edge
  //driver clocking block
  clocking driver_cb @(posedge clk);
    //input signals are sampled one time unit before the clock edge, and output signals are driven one time unit after the clock edge; this eliminates simultaneous read/write race conditions
    default input #1 output #1;

    output paddr;
    output penable;
    output psel;
    output pwrite;
    input  pready;
    input  pslverr;
    output pwdata;
    input  prdata;

  endclocking

  // monitor clocking block
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    input paddr;
    input penable;
    input psel;
    input pwrite;
    input pready;
    input pslverr;
    input pwdata;
    input prdata;
  endclocking

  //driver modport
  modport DRIVER  (clocking driver_cb,input clk,reset);

  //monitor modport
  modport MONITOR (clocking monitor_cb,input clk,reset);


   property PSEL_PENABLE;
     @(posedge clk) disable iff (!reset)
       $rose(psel) |=> $rose(penable);
   endproperty

    assert property (PSEL_PENABLE);

    property PWDATA_WHILE_WRITE;
       @(posedge clk) disable iff (!reset)
       (pwrite && psel&& penable) |-> $stable(pwdata);
     endproperty

      assert property (PWDATA_WHILE_WRITE);

     property PADDR_STABLE;
      @(posedge clk) disable iff (!reset)
       (psel && penable) |-> $stable(paddr);
     endproperty

       assert property (PADDR_STABLE);


    property PRDATA_WHILE_READ;
      @(posedge clk) disable iff (!reset)
        (!pwrite && psel && pready) |-> (prdata !== 32'hxxxxxxxx);
    endproperty

         assert property (PRDATA_WHILE_READ);


    property PSEL_DEFINED_STATE;
      @(posedge clk) disable iff (!reset)
      (psel !== 1'bx && psel !== 1'bz);
    endproperty

           assert property (PSEL_DEFINED_STATE);


    property PSEL_PREADY;
      @(posedge clk) disable iff (!reset)
       $fell(psel) |-> $fell(pready);
    endproperty

             assert property (PSEL_PREADY);

     property PSEL_PENABLE_FELL;
      @(posedge clk) disable iff (!reset)
       $fell(psel) |-> $fell(penable);
    endproperty

    assert property (PSEL_PENABLE_FELL);



    property PREADY_ONE_PULSE;
     @(posedge clk) disable iff (!reset)
       pready |=> !pready;
    endproperty

                 assert property (PREADY_ONE_PULSE);


   property PREADY_DEFINED_STATE;
     @(posedge clk) disable iff (!reset)
       (psel && penable) |-> (pready !== 1'bx && pready !== 1'bz);
    endproperty

   assert property (PREADY_DEFINED_STATE);


    property PENABLE_AFTER_PREADY;
     @(posedge clk) disable iff (!reset)
      $rose(penable) |-> psel;
    endproperty

     assert property (PENABLE_AFTER_PREADY);

     property PWRITE_DEFINED_STATE;
       @(posedge clk) disable iff (!reset)
        psel |-> (pwrite !== 1'bx && pwrite !== 1'bz);
     endproperty

     assert property (PWRITE_DEFINED_STATE);

     property PSEL_PENABLE_O;
      @(posedge clk) disable iff (!reset)
       $rose(psel) |-> !penable;
     endproperty

     assert property (PSEL_PENABLE_O);



endinterface
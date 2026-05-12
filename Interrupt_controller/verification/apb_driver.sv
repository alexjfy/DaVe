//the driver takes data from the generator at an abstract level and sends it to the DUT according to the communication protocol on the respective interface
//gets the packet from generator and drive the transaction packet items into interface (interface is connected to DUT, so the items driven into interface signal will get driven in to DUT)


//the DRIV_IF macro represents the interface through which the driver sends data to the DUT
`define DRIV_IF apb_vif.DRIVER.driver_cb
class apb_driver#(int AW=32, DW=32);

  //used to count the number of transactions
  int no_transactions;

  //creating virtual interface handle
  virtual apb_interface apb_vif;

  //mailbox port through which the driver receives abstract-level data from the generator
  //creating mailbox handle
  mailbox gen2driv;

  // constructor
  function new(virtual apb_interface apb_vif,mailbox gen2driv);
    //when the driver is created, its output interface is connected to the actual DUT interface
    //getting the interface
    this.apb_vif = apb_vif;
    //getting the mailbox handles from  environment
    this.gen2driv = gen2driv;
  endfunction

  //Reset task, Reset the Interface signals to default/initial values
  task reset;
    wait(apb_vif.reset == 0);
    $display("--------- [DRIVER] Reset Started ---------");
    `DRIV_IF.paddr <= 0;
    `DRIV_IF.psel <= 0;
    `DRIV_IF.penable  <= 0;
    `DRIV_IF.pwrite <= 0;
    `DRIV_IF.pwdata <= 0;
    //`DRIV_IF.prdata <= 1'bx;
    //`DRIV_IF.pready <= 1'bx;
    //`DRIV_IF.pslverr <= 1'bx;
    wait(apb_vif.reset == 1);
    $display("%0t--------- [DRIVER] Reset Ended ---------", $time());
  endtask

   //drives the transaction items to interface signals
  task drive;
    apb_transaction#(AW,DW) trans;
    trans = new();
    $display("before get");  // marker: waiting on the mailbox
     // `DRIV_IF.wr_en <= 0;
     // `DRIV_IF.rd_en <= 0;
    //if no data is available from the generator, the driver blocks at the line below until it receives data
      gen2driv.get(trans);
      $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);
    // Random per-transaction delay so back-to-back accesses aren't glued together
    repeat(trans.delay) @(apb_vif.DRIVER.clk);
    @(posedge apb_vif.clk);
    $display("%0t Driver transfer KIND %0s", $time,trans.kind.name());
        `DRIV_IF.paddr <= trans.addr;
    `DRIV_IF.psel <= 1'b1;
    `DRIV_IF.penable <= 1'b0;
    `DRIV_IF.pwrite <= (trans.kind == APB_WRITE) ? 1'b1 : 1'b0;
    if(trans.kind == APB_WRITE) `DRIV_IF.pwdata <= trans.data;

     @(posedge apb_vif.clk);
    `DRIV_IF.penable <= 1'b1;

    @(posedge apb_vif.clk);
    while (`DRIV_IF.pready == 1'b0) begin
      @(posedge apb_vif.clk);
    end
  	`DRIV_IF.psel <= 1'b0;
    `DRIV_IF.penable <= 1'b0;

      no_transactions++;
    $display("[DRV] %0t Transaction #%0d complete: %0s addr=0x%02h data=0x%08h", $time, no_transactions, trans.kind.name(), trans.addr, trans.data);
  endtask


  //The two threads below run in parallel. When the first one finishes, the second is automatically interrupted. If reset is activated, data transmission stops.
  task main;
    forever begin
      fork
         //Thread-1: Waiting for reset
        begin
          reset();
        end
        //Thread-2: Calling drive task
        begin
          //data transmission runs continuously, but is conditioned on receiving data from the generator.
          forever begin
            drive();
          end
        end
      join_any
      disable fork;
    end
  endtask

endclass
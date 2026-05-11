// The driver takes data from the generator at an abstract level and sends it
// to the DUT according to the communication protocol on the respective interface.
// Gets the packet from generator and drives the transaction packet items into
// interface (interface is connected to DUT, so the items driven into interface
// signal will get driven into DUT)


// The APB_DRIV_IF macro represents the interface through which the driver sends data to the DUT
`define APB_DRIV_IF apb_vif.DRIVER.driver_cb
class apb_driver;

  //used to count the number of transactions
  int no_transactions;

  //creating virtual interface handle
  virtual apb_interface apb_vif;

  // Mailbox port through which the driver receives abstract-level data from the generator
  //creating mailbox handle
  mailbox gen2driv;

  //constructor
  function new(virtual apb_interface apb_vif,mailbox gen2driv);
    // When the driver is created, the interface through which it sends data
    // is connected to the actual DUT interface
    //getting the interface
    this.apb_vif = apb_vif;
    //getting the mailbox handles from  environment
    this.gen2driv = gen2driv;
  endfunction

  //Reset task, Reset the Interface signals to default/initial values
  task reset;
    wait(apb_vif.reset); // wait for reset to be asserted
    $display("[DRIVER] Reset started");
    `APB_DRIV_IF.paddr <= 0;
    `APB_DRIV_IF.pwrite   <= 0;
    `APB_DRIV_IF.pwdata      <= 0;
     `APB_DRIV_IF.penable      <= 0;
     `APB_DRIV_IF.psel     <= 0;
    wait(!apb_vif.reset); // wait for reset to be deasserted
    $display("[DRIVER] Reset ended");
  endtask

  // Drives one APB transaction to the DUT.
  // APB transactions have two phases:
  //   - Setup phase (1 cycle): psel asserted, penable low, paddr/pwrite/pwdata valid
  //   - Access phase (1+ cycles): penable asserted, wait for pready from slave, then complete
  // After pready, signals are deasserted (cleanup) and an optional inter-transaction delay is applied.
  task drive;
      apb_transaction trans;

    // Blocks here until the generator puts a transaction into the mailbox
    gen2driv.get(trans);
    $display("[DRIVER] got transaction from mailbox: %s addr=0x%0h",
             trans.write_enable ? "WRITE" : "READ", trans.address);

    @(posedge apb_vif.DRIVER.clk);
    // APB Setup phase: psel=1, penable=0, paddr/pwrite valid, pwdata valid for writes
    `APB_DRIV_IF.paddr <= trans.address;
    `APB_DRIV_IF.pwrite <= trans.write_enable;
    `APB_DRIV_IF.psel <= 1;
    `APB_DRIV_IF.penable <= 0;
    if(trans.write_enable == 1) begin
        `APB_DRIV_IF.pwdata <= trans.data;
        $display("[DRIVER] setup phase: WRITE addr=0x%0h data=0x%0h", trans.address, trans.data);
    end
    else
        $display("[DRIVER] setup phase: READ addr=0x%0h", trans.address);

    @(posedge apb_vif.DRIVER.clk);
    // APB Access phase: penable goes high, slave must respond with pready==1
    `APB_DRIV_IF.penable <= 1;
    $display("[DRIVER] access phase: penable asserted, waiting for pready");

    @(posedge apb_vif.DRIVER.clk iff  `APB_DRIV_IF.pready == 1);
    $display("[DRIVER] pready received, transaction accepted by slave");

    // Cleanup: release the bus by deasserting control signals and driving data to X
    `APB_DRIV_IF.paddr <=  {ADDR_WIDTH{1'bx}};
    `APB_DRIV_IF.pwrite <= 1'b0;
     `APB_DRIV_IF.psel <= 1'b0;
     `APB_DRIV_IF.penable <= 1'b0;
     if(trans.write_enable == 1) begin
       `APB_DRIV_IF.pwdata <= {DATA_WIDTH{ 1'bx}};
     end
    @(posedge apb_vif.DRIVER.clk);

    // Optional inter-transaction delay (useful when stress-testing the slave with back-to-back traffic)
    if(trans.delay !=0) begin
      $display("[DRIVER] inserting %0d cycle(s) of inter-transaction delay", trans.delay);
      repeat (trans.delay)@(posedge apb_vif.DRIVER.clk);
    end
    no_transactions++;
    $display("[DRIVER] transfer #%0d complete", no_transactions);
  endtask


  // The two threads below run in parallel. After the first one finishes,
  // the second is automatically interrupted. If reset is asserted, data transmission stops.
  task main;
    forever begin
      fork
        //Thread-1: Waiting for reset
        begin
          wait(apb_vif.reset);
        end
        //Thread-2: Calling drive task
        begin
          // Data transmission runs continuously, but is conditioned on receiving data from the generator
          forever
            drive();
        end
      join_any
      disable fork;
    end
  endtask

endclass

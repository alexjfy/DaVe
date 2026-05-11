//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//The driver gets abstract-level data from the generator and drives it to the DUT
//according to the communication protocol on the respective interface.
//Gets the packet from generator and drives the transaction packet items into the interface
//(interface is connected to DUT, so the items driven into interface signals will get driven into DUT)

//Macro DRIV_IF represents the interface through which the driver sends data to the DUT
`define DRIV_IF_APB apb_vif.DRIVER.driver_cb
class driverAPB;
  
  //used to count the number of transactions
  int no_transactions;
  
  //creating virtual interface handle
  virtual apb_interface apb_vif;
  
  //Mailbox through which the driver receives abstract-level data from the generator
  //creating mailbox handle
  mailbox gen2driv;
  
  //constructor
  function new(virtual apb_interface apb_vif,mailbox gen2driv);
    //When the driver is created, the virtual interface is connected to the DUT's actual interface
    //getting the interface
    this.apb_vif = apb_vif;
    //getting the mailbox handles from  environment 
    this.gen2driv = gen2driv;
  endfunction
  
  //Reset task, Reset the Interface signals to default/initial values
  task reset;
    wait(!apb_vif.reset);
    $display("--------- [DRIVER] Reset Started ---------");
    `DRIV_IF_APB.psel    <= 0;
    `DRIV_IF_APB.penable <= 0;
    `DRIV_IF_APB.pwrite  <= 0;
    `DRIV_IF_APB.pwdata  <= 0;
    `DRIV_IF_APB.paddr   <= 0;
    wait(apb_vif.reset);
    $display("--------- [DRIVER] Reset Ended ---------");
  endtask
  
  //drives the transaction items to interface signals
  task drive;
      transactionAPB trans;
    trans = new();
    //If no data from the generator, the driver blocks at the line below until data is received
      gen2driv.get(trans);
    
      `DRIV_IF_APB.psel    <= 1'b0;
      `DRIV_IF_APB.penable <= 1'b0;
 
      $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);
    repeat(trans.delay) @(apb_vif.DRIVER.clk);
    @(posedge apb_vif.clk);
        `DRIV_IF_APB.paddr <= trans.addr;
        `DRIV_IF_APB.psel   <= 1'b1;
        `DRIV_IF_APB.pwrite <= trans.write;
    if(trans.write) begin
      `DRIV_IF_APB.pwdata <= trans.data;
       $display("\tADDR = %0h \tWDATA = %0h",trans.addr,trans.data);
    end
    @(posedge apb_vif.clk);
        `DRIV_IF_APB.penable <= 1'b1;
       
    @(posedge apb_vif.clk);
    while (`DRIV_IF_APB.pready == 1'b0) begin
      @(posedge apb_vif.clk);
    end
    if (~trans.write) begin
      $display("T=%0t [DRIVER] READ  addr=0x%0h rdata=0x%0h pslverr=%0b", $time, trans.addr, `DRIV_IF_APB.prdata, `DRIV_IF_APB.pslverr);
    end else begin
      $display("T=%0t [DRIVER] WRITE addr=0x%0h wdata=0x%0h", $time, trans.addr, trans.data);
    end
      `DRIV_IF_APB.psel   <= 1'b0;
      `DRIV_IF_APB.pwrite <= 1'b0;
      `DRIV_IF_APB.penable<= 1'b0;
      `DRIV_IF_APB.pwdata <= 32'bx;
      `DRIV_IF_APB.paddr  <= 32'bx;
      no_transactions++;
  endtask
  
    
  //The two threads below run in parallel. When the first one finishes, the second is automatically stopped. If reset is activated, no more data is transmitted.
  task main;
    forever begin
      fork
        //Thread-1: Waiting for reset
        begin
//           wait(!apb_interface_driver.reset);
          reset();
        end
        //Thread-2: Calling drive task
        begin
          //Data transmission runs continuously, but is conditioned on receiving data from the generator.
          forever
            drive();
        end
      join_any
      disable fork;
    end
  endtask
        
endclass
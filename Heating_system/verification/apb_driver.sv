
//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//the driver receives data from the generator at an abstract level and sends it to the DUT according to the communication protocol on the respective interface
//gets the packet from generator and drive the transaction paket items into interface (interface is connected to DUT, so the items driven into interface signal will get driven in to DUT) 


//define the APB_DRIV_IF macro representing the interface through which the driver sends data to the DUT
`define APB_DRIV_IF apb_vif.DRIVER.driver_cb
class apb_driver;
  
  //used to count the number of transactions
  int no_transactions;
  
  //creating virtual interface handle
  virtual apb_interface apb_vif;
  
  //create the port through which the driver receives abstract-level data from the generator
  //creating mailbox handle
  mailbox gen2driv;
  
  //constructor
  function new(virtual apb_interface apb_vif,mailbox gen2driv);
    //when the driver is created, its interface is connected to the actual DUT interface
    //getting the interface
    this.apb_vif = apb_vif;
    //getting the mailbox handles from  environment 
    this.gen2driv = gen2driv;
  endfunction
  
  //Reset task, Reset the Interface signals to default/initial values
  task reset;
    wait(apb_vif.reset);
    $display("--------- [APB DRIVER] Reset Started ---------");
    `APB_DRIV_IF.pwrite <= 0;
    `APB_DRIV_IF.penable <= 0;
    `APB_DRIV_IF.paddr  <= 0;
    `APB_DRIV_IF.psel  <= 0;
    `APB_DRIV_IF.pwdata <= 0;        
    wait(!apb_vif.reset);
    $display("--------- [APB DRIVER] Reset Ended ---------");
  endtask
  
  //drives the transaction items to interface signals
  task drive;
      apb_transaction trans;
    //if there is no data from the generator, the driver blocks at the line below until data is received
      gen2driv.get(trans);
    $display("--------- [APB DRIVER-TRANSFER: %0d] ---------",no_transactions);
        `APB_DRIV_IF.paddr <= trans.paddr;
        `APB_DRIV_IF.pwrite <= trans.pwrite;
    if(trans.pwrite == 1) begin
        `APB_DRIV_IF.pwdata <= trans.data;
      $display("\tADDR = %0h \tWDATA = %0h",trans.paddr,trans.data);
          end
       `APB_DRIV_IF.psel <= 1;
        `APB_DRIV_IF.penable <= 0;
        @(posedge apb_vif.DRIVER.clk);
        `APB_DRIV_IF.penable <= 1;
    @(posedge apb_vif.DRIVER.clk iff  `APB_DRIV_IF.pready == 1);
    `APB_DRIV_IF.paddr <= {ADDR_WIDTH{1'bx}};
    `APB_DRIV_IF.pwrite <= 1'bx;
    `APB_DRIV_IF.psel <= 0;
    `APB_DRIV_IF.penable <= 1'bx;
    `APB_DRIV_IF.pwdata <= {DATA_WIDTH{1'bx}};
    
        $display("\tADDR = %0h \tRDATA = %0h",trans.paddr,`APB_DRIV_IF.prdata);

      $display("-----------------------------------------");
      no_transactions++;
  endtask
  
    
  //The two threads below run in parallel. When the first one finishes, the second is automatically interrupted. If reset is asserted, data transmission stops.
  task main;
    forever begin
      fork
        //Thread-1: Waiting for reset
        begin
          wait(apb_vif.reset);
        end
        //Thread-2: Calling drive task
        begin
          //data transmission runs continuously, but is conditioned on receiving data from the generator.
          forever
            drive();
        end
      join_any
      disable fork;
    end
  endtask
        
endclass
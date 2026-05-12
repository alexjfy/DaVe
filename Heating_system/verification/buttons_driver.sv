//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//the driver receives data from the generator at an abstract level and sends it to the DUT according to the communication protocol on the respective interface
//gets the packet from generator and drive the transaction paket items into interface (interface is connected to DUT, so the items driven into interface signal will get driven in to DUT) 


//the OUTPUTDRIV_IF macro represents the interface through which the driver sends data to the DUT
`define OUTPUTDRIV_IF btn_vif.DRIVER.driver_cb
class buttons_driver;
  
  //used to count the number of transactions
  int no_transactions;
  
  //creating virtual interface handle
  virtual buttons_interface btn_vif;
  
  //the port through which the driver receives abstract-level data from the generator
  //creating mailbox handle
  mailbox gen2driv;
  
  //constructor
  function new(virtual buttons_interface btn_vif,mailbox gen2driv);
    //when the driver is created, its interface is connected to the actual DUT interface
    //getting the interface
    this.btn_vif = btn_vif;
    //getting the mailbox handles from  environment 
    this.gen2driv = gen2driv;
  endfunction
  
  //Reset task, Reset the Interface signals to default/initial values
  task reset;
    wait(btn_vif.reset);
    $display("--------- [BUTTONS DRIVER] Reset Started ---------");
    `OUTPUTDRIV_IF.button_mod_econ <= 0;
    `OUTPUTDRIV_IF.button_mod_comf <= 0;
    `OUTPUTDRIV_IF.button_mod_thermo  <= 0;
    `OUTPUTDRIV_IF.button_child_prot <= 0;        
    wait(!btn_vif.reset);
    $display("--------- [BUTTONS DRIVER] Reset Ended ---------");
  endtask
  
  //drives the transaction items to interface signals
  task drive;
      buttons_transaction trans;
    //if no data is available from the generator, the driver blocks at the line below until data is received
      gen2driv.get(trans);
    $display("--------- [BUTTONS DRIVER-TRANSFER: %0d] ---------",no_transactions);
      repeat(trans.delay)@(posedge btn_vif.DRIVER.clk);
        `OUTPUTDRIV_IF.button_mod_thermo <= trans.button_mod_thermo;
        `OUTPUTDRIV_IF.button_mod_econ <= trans.button_mod_econ;
        `OUTPUTDRIV_IF.button_child_prot <= trans.button_child_prot;
        `OUTPUTDRIV_IF.button_mod_comf <= trans.button_mod_comf;
      // hold the buttons for multiple cycles, not just 1
      repeat(trans.hold) @(posedge btn_vif.DRIVER.clk);
        `OUTPUTDRIV_IF.button_mod_thermo <= 0;
        `OUTPUTDRIV_IF.button_mod_econ <= 0;
        `OUTPUTDRIV_IF.button_child_prot <= 0;
        `OUTPUTDRIV_IF.button_mod_comf <= 0;
      
      $display("-----------------------------------------");
      no_transactions++;
  endtask
  
    
  //The two threads below run in parallel. When the first one finishes, the second is automatically terminated. If reset is asserted, data transmission stops.
  task main;
    forever begin
      fork
        //Thread-1: Waiting for reset
        begin
          wait(btn_vif.reset);
        end
        //Thread-2: Calling drive task
        begin
          //data is sent continuously, but it depends on receiving data from the monitor.
          forever
            drive();
        end
      join_any
      disable fork;
    end
  endtask
        
endclass
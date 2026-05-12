//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------

//all verification components are instantiated in the verification environment
`include "apb_transaction.sv"
`include "buttons_transaction.sv"
`include "output_transaction.sv"
`include "apb_driver.sv"
`include "buttons_driver.sv"
//`include "transaction.sv"
//`include "generator.sv"
//`include "apb_driver.sv"
//`include "driver.sv"
//`include "monitor.sv"
//`include "coverage.sv"
//`include "scoreboard.sv"
`include "apb_coverage.sv"
`include "apb_monitor.sv"
`include "apb_generator.sv"
`include "output_coverage.sv"
`include "output_monitor.sv"
`include "output_generator.sv"
`include "buttons_coverage.sv"
`include "buttons_monitor.sv"
`include "buttons_generator.sv"



class environment;
  
  //verification components are declared
  //generator and driver instance
  apb_generator  apb_gen;
  apb_driver     apb_driv;
  apb_monitor    apb_mon; 
  
  output_monitor     out_mon;
  
  buttons_driver     buttons_driv;
  buttons_generator  buttons_gen;
  buttons_monitor    buttons_mon;
  
 
//  scoreboard scb;
  
  // mailboxes connecting generators -> drivers and monitors -> scoreboard
  // buttons_gen2driv is also accessed directly by directed tests (all_modes_test)
  mailbox  apb_gen2driv = new();
  mailbox  apb_mon2scb  = new();

  mailbox  out_mon2scb  = new();

  mailbox  buttons_gen2driv = new();
  mailbox  buttons_mon2scb  = new();
    
  
  //event for synchronization between generator and test
  event gen_ended;
  
  //virtual interface
  virtual apb_interface apb_vif;
  virtual output_interface out_vif;
  virtual buttons_interface buttons_vif;
  
  //constructor
  function new(virtual apb_interface apb_vif, virtual output_interface out_vif, virtual buttons_interface buttons_vif );//the 3 virtual interfaces
    
    //get the interface from test
    this.apb_vif = apb_vif;
     this.out_vif = out_vif;
     this.buttons_vif = buttons_vif;
    
    //creating the mailbox (Same handle will be shared across generator and driver)
    apb_gen2driv = new();
    apb_mon2scb  = new();

    out_mon2scb  = new();
    
    buttons_gen2driv = new();
    buttons_mon2scb  = new();
    
    
    //verification components are created
    //creating generator and driver
    apb_gen  = new(apb_gen2driv,gen_ended);
    apb_driv = new(apb_vif,apb_gen2driv);
    apb_mon  = new(apb_vif,apb_mon2scb);
    
    out_mon  = new(out_vif,out_mon2scb);
    
    buttons_gen = new(buttons_gen2driv,gen_ended);
    buttons_driv = new(buttons_vif,buttons_gen2driv);
    buttons_mon = new(buttons_vif,buttons_mon2scb);
    
 //   scb  = new(mon2scb);
  endfunction
  
  // assert reset and hold all interface signals at safe defaults
  task pre_test();
    fork
      buttons_driv.reset();
      apb_driv.reset();
    join
  endtask

  // launch all drivers and monitors in parallel; join_any exits as soon as
  // the generator finishes (or reset is re-asserted in a driver)
  task test();
    fork
      apb_driv.main();
      apb_mon.main();
      out_mon.main();
      buttons_gen.main();
      buttons_driv.main();
      buttons_mon.main();
    join_any
  endtask

  task post_test();
    // wait until the driver has processed every transaction the generator produced,
    // then give the DUT a few extra cycles to settle before reading coverage
    wait(buttons_gen.repeat_count == buttons_driv.no_transactions);
    #10000;
  endtask

  function report();
    apb_mon.apb_coverage_colector.print_coverage();
    out_mon.output_coverage_colector.print_coverage();
  endfunction

  // top-level sequence: reset -> run components -> wait for end -> print coverage -> finish
  task run;
    pre_test();
    test();
    post_test();
    report();
    $finish;
  endtask
  
endclass


`include "apb_transaction.sv"
`include "out_transaction.sv"
`include "apb_generator.sv"
`include "apb_driver.sv"
`include "apb_coverage.sv"
`include "apb_monitor.sv"
`include "out_coverage.sv"
`include "out_monitor.sv"
`include "scoreboard.sv"
class environment#(int AW=32, DW=32);

  //verification components are declared
  //generator and driver instance
  apb_generator#(AW,DW)  gen;
  apb_driver#(AW,DW)     driv;
  apb_monitor#(AW,DW)    apb_mon;
  out_monitor   out_mon;
  scoreboard 	scb;

  //mailbox handle's
  mailbox gen2driv;
  mailbox apb_mon2scb;
  mailbox out_mon2scb;

  //flag for synchronization between generator and test
  //event replaced with bit flag for XSIM compatibility

  //virtual interface
  virtual apb_interface apb_vif;
  virtual out_interface out_vif;

  // constructor
  function new(virtual apb_interface apb_vif, virtual out_interface out_vif);
    //get the interface from test
    this.apb_vif  = apb_vif;
    this.out_vif = out_vif;

    //creating the mailbox (Same handle will be shared across generator and driver)
    gen2driv = new();
    apb_mon2scb = new();
    out_mon2scb  = new();

    //verification components are created
    //creating generator and driver
    gen  	= new(gen2driv);
    driv 	= new(apb_vif,gen2driv);
    apb_mon = new(apb_vif,apb_mon2scb);
    out_mon = new(out_vif, out_mon2scb);
    scb  	= new(apb_mon2scb, out_mon2scb);
  endfunction

  //
  task pre_test();
   // driv.reset();
  endtask

  task test();
    fork
   // gen.main();
    driv.main();
    apb_mon.main();
    out_mon.main();
    scb.main();

    join_none

  endtask

  task post_test();
    #50000;
   // wait(gen.gen_done == 1);
    //ensure all generated data is transmitted to the DUT and also reaches the scoreboard
   //   wait(4< driv.no_transactions);
 ///   wait(gen.repeat_count == scb.no_transactions);
  endtask

  function void report();
    //scb.colector_coverage.print_coverage();
    out_mon.out_coverage_inst.print_coverage();
  	apb_mon.apb_coverage_inst.print_coverage();

  endfunction


  //run task
  task run;
    pre_test();
    test();
    post_test();
    report();
    //the line below is necessary for the simulation to finish
  //  #1000
    $finish;
  endtask

endclass
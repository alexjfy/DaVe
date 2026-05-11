//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------

//The verification environment instantiates all verification components
`include "transactionAPB.sv"
`include "IRQ_transaction.sv"
`include "irq_coverage.sv"
`include "IRQ_monitor.sv"
`include "generatorAPB.sv"
`include "result_transaction.sv"
`include "coverageAPB.sv"
`include "driverAPB.sv"
`include "monitorAPB.sv"
`include "result_coverage.sv"
`include "result_monitor.sv"
//`include "scoreboard.sv"
class environment;
  
  //Verification components are declared
  //generator and driverAPB instance
  generatorAPB  gen;
  driverAPB     apb_drv;
  monitorAPB    apb_mon;
  result_monitor    result_mon;
  IRQ_monitor		irq_mon;
  //scoreboard scb;
  
  //mailbox handle's
  mailbox gen2apb_drv;
  
  
  mailbox output_mon2scb;
  mailbox apb_mon2scb;
  mailbox irq_mon2scb;
  
  //event for synchronization between generator and test
  event gen_ended;
  
  //virtual interface
  virtual output_interface output_interface_instance;
  virtual apb_interface apb_interface_instance;
  virtual irq_interface irq_interface_instance;
  
  //constructor
  function new(virtual output_interface output_interface_instance, virtual apb_interface apb_interface_instance, virtual irq_interface irq_interface_instance);
    //get the interface from test
    this.output_interface_instance = output_interface_instance;
    this.apb_interface_instance = apb_interface_instance;
    this.irq_interface_instance = irq_interface_instance;
    
    //creating the mailbox (Same handle will be shared across generator and driverAPB)
    gen2apb_drv = new();
    output_mon2scb  = new();
    apb_mon2scb = new();
    irq_mon2scb = new();
    
    //Verification components are created
    //creating generator and driverAPB

    gen  = new(gen2apb_drv,gen_ended);
//     gen.repeat_count = 10;
    apb_drv = new(apb_interface_instance,gen2apb_drv);
    result_mon  = new(output_interface_instance,output_mon2scb);
    apb_mon  = new(apb_interface_instance,apb_mon2scb);
    irq_mon = new(irq_interface_instance, irq_mon2scb);

  //  scb  = new(output_mon2scb);
  endfunction
  
  //
  task pre_test();
   apb_drv.reset();
  endtask
  
  task test();
    fork 
      apb_drv.main();
      gen.main();
      apb_mon.main();
      result_mon.main();
      irq_mon.main();  
  //  scb.main();      
    join_any
  endtask
  
  task post_test();
//      #2000;
    $display("\t repeat  = %0d\t no_transactions = %0d", gen.repeat_count, apb_drv.no_transactions);
//    wait(gen_ended.triggered);
//     Ensure all generated data is transmitted to the DUT and reaches the scoreboard
   wait(gen.repeat_count == apb_drv.no_transactions);
//    wait(gen.repeat_count == scb.no_transactions);
  endtask  
  
  function report();
    //scb.colector_coverage.print_coverage();
    apb_mon.coverage_collector.print_coverage();
    result_mon.coverage_collector.print_coverage();
    irq_mon.coverage_collector.print_coverage();
  endfunction
  
  //run task
  task run;
    pre_test();
    test();
    post_test();
    report();
    //The line below is necessary for the simulation to finish
    #10000
    $finish;
  endtask
  
endclass



// All verification components are instantiated in the verification environment

`include "out_transaction.sv"
`include "out_coverage.sv"
`include "out_monitor.sv"
`include "apb_transaction.sv"
`include "apb_coverage.sv"
`include "apb_generator.sv"
`include "apb_driver.sv"
`include "apb_monitor.sv"
`include "scoreboard.sv"

class environment;

  // Verification components declaration
  //generator and driver instance
  apb_generator  gen;
  apb_driver     driv;
   out_monitor    out_mon;
   apb_monitor    apb_mon;
 virtual out_interface   out_interf;
 virtual apb_interface   apb_interf;
   out_coverage    out_cover;
   apb_coverage    apb_cover;

  scoreboard scb;

  //mailbox handle's
  mailbox gen2driv;
  mailbox out_mon2scb;
  mailbox apb_mon2scb;

  //event for synchronization between generator and test
  event gen_ended;

  //virtual interface
  //constructor
  function new(virtual out_interface  out_interfa, virtual apb_interface   apb_interfa);
    //get the interface from test
    this.apb_interf = apb_interfa ;
    this.out_interf = out_interfa ;

    //creating the mailbox (Same handle will be shared across generator and driver)
    gen2driv = new();
    out_mon2scb  = new();
    apb_mon2scb  = new();
    // Verification components are created
    //creating generator and driver
    gen  = new(gen2driv,gen_ended);
    driv = new(apb_interf,gen2driv);
    apb_mon  = new(apb_interf,apb_mon2scb);
    out_mon  = new(out_interf,out_mon2scb);

   // scb  = new(out_mon2scb, apb_mon2scb);
  endfunction

  // pre_test: handles the reset sequence so stimulus starts from a known DUT state
  task pre_test();
    $display("[ENV] pre_test: resetting DUT");
    driv.reset();
  endtask

  // test: launches the driver and the two monitors in background threads (join_none)
  // so they run forever. If the generator has repeat_count > 0 we also run it for
  // random tests; for directed tests the stimulus comes from write_register/read_register
  // called directly in the test program.
  task test();
    $display("[ENV] test: starting stimulus and monitors");
    fork
    driv.main();
    out_mon.main();
    apb_mon.main();
    join_none
    if (gen.repeat_count > 0)
      gen.main();
  endtask

  // post_test: wait for all pending transactions in the mailbox to be consumed and
  // for the last one to actually complete on the APB bus (takes a few extra cycles).
  task post_test();
    $display("[ENV] post_test: waiting for pending transactions to drain");
    forever begin
      wait(gen2driv.num() == 0);
      repeat(50) @(posedge apb_interf.clk);
      if (gen2driv.num() == 0)
        break;
    end
    $display("[ENV] post_test: all transactions drained (%0d transfers total)", driv.no_transactions);
  endtask

  task report();
    $display("[ENV] Coverage report");
    $display("[ENV] Output interface:");
    out_mon.coverage_collector.print_coverage();
    $display("[ENV] APB interface:");
    apb_mon.covera.print_coverage();
  endtask

  // Top-level test flow: reset -> run stimulus -> wait for drain -> print coverage -> finish
  task run;
    $display("[ENV] Test started");
    pre_test();
    test();
    post_test();
    report();
    $display("[ENV] Test finished");
    $finish;
  endtask

endclass

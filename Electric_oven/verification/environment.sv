// Verification Environment
// Description: Instantiates and wires together all verification components —
//              generators, drivers, monitors, coverage collectors, scoreboard —
//              and exposes pre_test / test / post_test / report / run phases.

// Transactions
`include "apb_transaction.sv"
`include "led_transaction.sv"
`include "door_transaction.sv"

// Drivers
`include "apb_driver.sv"
`include "door_driver.sv"

// Coverage collectors
`include "apb_coverage.sv"
`include "door_coverage.sv"
`include "led_coverage.sv"

// Monitors
`include "apb_monitor.sv"
`include "led_monitor.sv"
`include "door_monitor.sv"

// Generators
`include "apb_generator.sv"
`include "door_generator.sv"

// Scoreboard / reference model
`include "scoreboard.sv"

class environment;

    // Verification components
    apb_generator  apb_gen;
    door_generator door_gen;
    apb_driver     apb_driv;
    door_driver    door_driv;
    apb_monitor    apb_mon;
    led_monitor    led_mon;
    door_monitor   door_mon;
    scoreboard     scb;

    // Mailboxes connecting producers to consumers.
    mailbox apb_gen2driv;
    mailbox door_gen2driv;
    mailbox apb_mon2scb;
    mailbox led_mon2scb;
    mailbox door_mon2scb;

    // Event shared by generators to signal end-of-generation.
    event gen_ended;

    // Virtual interface handles, bound at construction from the testbench.
    virtual apb_interface  apb_vif;
    virtual door_interface door_vif;
    virtual led_interface  led_vif;

    // Upper bound on the simulation time spent in post_test (time units).
    int sim_timeout = 50000;

    // Constructor: connects every verification component to its mailbox and interface.
    function new(virtual apb_interface apb_vif, virtual door_interface door_vif, virtual led_interface led_vif);
        this.apb_vif  = apb_vif;
        this.door_vif = door_vif;
        this.led_vif  = led_vif;

        // Create mailboxes.
        apb_gen2driv  = new();
        door_gen2driv = new();
        apb_mon2scb   = new();
        led_mon2scb   = new();
        door_mon2scb  = new();

        // Create verification components and wire them to the mailboxes/interfaces.
        apb_gen   = new(apb_gen2driv, gen_ended);
        door_gen  = new(door_gen2driv, gen_ended);
        apb_driv  = new(apb_vif, apb_gen2driv);
        door_driv = new(door_vif, door_gen2driv);
        apb_mon   = new(apb_vif, apb_mon2scb);
        door_mon  = new(door_vif, door_mon2scb);
        led_mon   = new(led_vif, led_mon2scb);
        scb       = new(apb_mon2scb, door_mon2scb, led_mon2scb);
    endfunction

    // Pre-test phase: block until reset has been released by the testbench.
    task pre_test();
        $display("%0t [ENV] Pre-test phase: waiting for reset to complete...", $time());
        wait(apb_vif.reset === 0);
        $display("%0t [ENV] Reset complete, starting test.", $time());
    endtask

    // Test phase: launch all driver/monitor/scoreboard threads in parallel.
    task test();
        fork
            door_gen.main();
            apb_driv.main();
            door_driv.main();
            apb_mon.main();
            door_mon.main();
            led_mon.main();
            scb.main();
        join_none
    endtask

    // Post-test phase: give the simulation enough time to complete any in-flight
    // countdown before reporting. sim_timeout is configurable so longer tests
    // (e.g., timer=125 cycles) can still finish before the final report.
    task post_test();
        $display("%0t [ENV] Post-test: waiting %0d time units for simulation to complete...",
                 $time(), sim_timeout);
        #(sim_timeout);
    endtask

    // Report phase: print coverage for each monitor and the scoreboard statistics.
    function void report();
        $display("");
        $display("[ENV] COVERAGE REPORT");
        void'(apb_mon.coverage_collector.print_coverage());
        void'(door_mon.coverage_collector.print_coverage());
        void'(led_mon.coverage_collector.print_coverage());
        $display("");
        scb.print_stats();
    endfunction

    // Run: orchestrates the full verification flow (pre_test -> test -> post_test -> report).
    task run;
        $display("%0t [ENV] SIMULATION START", $time());
        pre_test();
        test();
        post_test();
        report();
        $display("%0t [ENV] SIMULATION END", $time());
        $finish;
    endtask

endclass

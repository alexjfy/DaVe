// The monitor observes traffic on the DUT interfaces, captures verified data
// and reconstructs transactions (using transaction class objects); in this
// implementation, the captured data is sent to the scoreboard for verification.
// Samples the interface signals, captures into transaction packet and send the packet to scoreboard.

// The OUT_MON_IF macro holds the signal block from which the monitor extracts data
`define OUT_MON_IF interface_instance.MONITOR.monitor_cb
class out_monitor;

  //creating virtual interface handle
  virtual out_interface interface_instance;

  // Mailbox port through which the monitor sends collected data to the scoreboard as transactions
  //creating mailbox handle
  mailbox mon2scb;

  out_coverage coverage_collector;

  // When the monitor object is created (in environment.sv), the interface from which
  // it collects data is connected to the actual DUT interface
  //constructor
  function new(virtual  out_interface interface_instance, mailbox mon2scb);
    //getting the interface
    this. interface_instance= interface_instance;
    //getting the mailbox handles from  environment
    this.mon2scb = mon2scb;

    coverage_collector = new();
  endfunction

  // Tracks the previous output state so we only log when something actually changes
  // (otherwise a display every clock cycle would flood the log).
  bit last_wipers       = 0;
  bit last_high_beam    = 0;
  bit last_flash        = 0;
  bit last_washer       = 0;
  bit last_right_signal = 0;
  bit last_left_signal  = 0;

  // Samples the output interface every clock cycle, packages the values as a transaction,
  // sends it to the scoreboard for checking and feeds the coverage collector.
  // Logs a line only when at least one output changes, to keep the console readable.
  task main;
    forever begin
      out_transaction trans;
      trans = new();

      @(posedge interface_instance.MONITOR.clk);
        trans.wipers       = `OUT_MON_IF.wipers;
        trans.high_beam    = `OUT_MON_IF.high_beam;
        trans.washer       = `OUT_MON_IF.washer;
        trans.flash        = `OUT_MON_IF.flash;
        trans.right_signal = `OUT_MON_IF.right_signal;
        trans.left_signal  = `OUT_MON_IF.left_signal;

      if (trans.wipers       !== last_wipers       ||
          trans.high_beam    !== last_high_beam    ||
          trans.flash        !== last_flash        ||
          trans.washer       !== last_washer       ||
          trans.right_signal !== last_right_signal ||
          trans.left_signal  !== last_left_signal) begin
        $display("[OUT-MON] outputs: wipers=%0b hb=%0b flash=%0b washer=%0b r_sig=%0b l_sig=%0b",
                 trans.wipers, trans.high_beam, trans.flash, trans.washer,
                 trans.right_signal, trans.left_signal);
        last_wipers       = trans.wipers;
        last_high_beam    = trans.high_beam;
        last_flash        = trans.flash;
        last_washer       = trans.washer;
        last_right_signal = trans.right_signal;
        last_left_signal  = trans.left_signal;
      end

      mon2scb.put(trans);
      coverage_collector.sample(trans);
    end
  endtask

endclass

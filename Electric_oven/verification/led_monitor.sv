// LED monitor: samples the led output signal on every clock edge, wraps it
// in a led_transaction, and forwards it to both the scoreboard and the
// coverage collector.
class led_monitor;

  // Virtual interface handle — connected to the actual DUT interface at construction.
  virtual led_interface led_vif;

  // Coverage collector instantiated alongside this monitor.
  led_coverage coverage_collector;

  // Mailbox through which captured transactions are sent to the scoreboard.
  mailbox mon2scb;

  // Constructor: binds the interface and mailbox, creates the coverage object.
  function new(virtual led_interface led_vif, mailbox mon2scb);
    this.led_vif = led_vif;
    this.mon2scb = mon2scb;
    coverage_collector = new();
  endfunction

  // Main task: runs forever, sampling the LED output every clock cycle.
  task main;
    forever begin
      led_transaction trans = new();

      // Sample on the rising clock edge using the monitor clocking block.
      @(posedge led_vif.clk);
      trans.led = led_vif.monitor_cb.led;

      // Send the captured transaction to the scoreboard and record coverage.
      mon2scb.put(trans);
      coverage_collector.sample(trans);
    end
  endtask

endclass

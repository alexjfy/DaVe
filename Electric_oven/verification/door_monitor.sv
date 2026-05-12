// Door monitor: samples the door_closed signal on every clock edge, wraps it
// in a door_transaction, and forwards it to both the scoreboard and the
// coverage collector.
`define DOOR_MON_IF door_vif.monitor_cb

class door_monitor;

  // Virtual interface handle — connected to the actual DUT interface at construction.
  virtual door_interface door_vif;

  // Coverage collector instantiated alongside this monitor.
  door_coverage coverage_collector;

  // Mailbox through which captured transactions are sent to the scoreboard.
  mailbox mon2scb;

  // Constructor: binds the interface and mailbox, creates the coverage object.
  function new(virtual door_interface door_vif, mailbox mon2scb);
    this.door_vif = door_vif;
    this.mon2scb  = mon2scb;
    coverage_collector = new();
  endfunction

  // Main task: runs forever, sampling the door interface every clock cycle.
  task main;
    forever begin
      door_transaction trans;
      trans = new();

      // Sample on the rising clock edge using the monitor clocking block.
      @(posedge door_vif.clk);
      trans.door_closed = `DOOR_MON_IF.door_closed;

      // Send the captured transaction to the scoreboard and record coverage.
      mon2scb.put(trans);
      coverage_collector.sample(trans);
    end
  endtask

endclass

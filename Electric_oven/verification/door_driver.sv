// The driver takes transactions from the generator at the abstract level and drives
// them onto the DUT interface following the door interface protocol.

// Macro for the driver clocking block to keep signal references concise.
`define DRIV_IF door_vif.driver_cb

class door_driver;

  // Counter for the total number of transactions driven.
  int no_transactions;

  // Virtual interface handle — connected to the actual DUT interface at construction.
  virtual door_interface door_vif;

  // Mailbox through which the driver receives transactions from the generator.
  mailbox gen2driv;

  // Constructor: binds the interface and mailbox passed in from the environment.
  function new(virtual door_interface door_vif, mailbox gen2driv);
    this.door_vif = door_vif;
    this.gen2driv = gen2driv;
  endfunction

  // Reset task: holds door_closed low while reset is active, then waits for deassertion.
  task reset;
    wait(door_vif.reset);
    $display("%0t [DOOR-DRIVER] Reset started", $time());
    `DRIV_IF.door_closed <= 0;
    wait(!door_vif.reset);
    $display("%0t [DOOR-DRIVER] Reset ended", $time());
  endtask

  // Drive task: retrieves one transaction from the mailbox and applies it to the interface.
  task drive;
    door_transaction trans;
    // Block here until the generator places a transaction in the mailbox.
    gen2driv.get(trans);
    $display("%0t [DOOR-DRIVER] Transfer #%0d: door_closed=%0b",
             $time(), no_transactions, trans.door_closed);
    @(posedge door_vif.clk);
    `DRIV_IF.door_closed <= trans.door_closed;
    @(posedge door_vif.clk);
    no_transactions++;
  endtask

  // Main task: two parallel threads — one monitors reset, the other drives continuously.
  // When reset is asserted the driving thread is killed; it restarts after deassertion.
  task main;
    forever begin
      fork
        // Thread 1: wait for reset assertion and deassertion.
        begin
          reset();
        end
        // Thread 2: drive transactions continuously while reset is inactive.
        begin
          forever
            drive();
        end
      join_any
      disable fork;
    end
  endtask

endclass

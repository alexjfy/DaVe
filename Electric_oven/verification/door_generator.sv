// Generator for door transactions. Produces a configurable number of randomized
// door_transaction objects and places them in the mailbox for the driver.
class door_generator;

  // Two transaction handles: trans is reused for randomization, tr holds the deep copy.
  rand door_transaction trans, tr;

  // Number of transactions to generate per test run.
  int repeat_count = 20;

  // Mailbox shared with the door driver.
  mailbox gen2driv;

  // Event signaled when all transactions have been placed in the mailbox.
  event gen_done;

  // Constructor: receives the shared mailbox and end event from the environment.
  function new(mailbox gen2driv, event gen_done);
    this.gen2driv = gen2driv;
    this.gen_done = gen_done;
    trans = new();
  endfunction

  // Main task: generates repeat_count randomized transactions and queues them.
  task main();
    $display("%0t [DOOR-GEN] Starting: will generate %0d transactions", $time(), repeat_count);
    repeat(repeat_count) begin
      if (!trans.randomize())
        $fatal(1, "DOOR-GEN: transaction randomization failed");
      tr = trans.do_copy();
      gen2driv.put(tr);
      $display("%0t [DOOR-GEN] Transaction queued: door_closed=%0b", $time(), tr.door_closed);
    end
    $display("%0t [DOOR-GEN] All %0d transactions generated", $time(), repeat_count);
    -> gen_done;
  endtask

endclass

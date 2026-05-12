// APB Generator
// Description: Creates randomized or directed APB transactions and places them
//              in the mailbox shared with the APB driver. Supports both fully
//              random generation (via main()) and directed read/write helpers.
`include "defines.sv"

class apb_generator;

  // Two handles: trans is reused for randomization, tr holds the deep copy.
  rand apb_transaction trans, tr;

  // Number of transactions to generate in the fully-random flow.
  int repeat_count;

  // Mailbox shared with the APB driver.
  mailbox gen2driv;

  // Event signaled when all transactions have been queued.
  event gen_done;

  // Constructor: binds the mailbox and the end event, creates the initial transaction.
  function new(mailbox gen2driv, event gen_done);
    this.gen2driv = gen2driv;
    this.gen_done = gen_done;
    trans = new();
  endfunction

  // Fully random flow — generates repeat_count transactions constrained only by the
  // class constraints (valid addresses, delay range).
  task main();
    $display("%0t [APB-GEN] Starting random flow: %0d transactions", $time(), repeat_count);
    repeat(repeat_count) begin
      if (!trans.randomize())
        $fatal(1, "APB-GEN: transaction randomization failed");
      tr = trans.do_copy();
      gen2driv.put(tr);
    end
    -> gen_done;
  endtask

  // Directed helper: queues a write transaction to the given address with the given data.
  task write_reg_transaction(bit [`ADDR_WIDTH-1:0] paddr_arg, bit [`DATA_WIDTH-1:0] data_arg);
    if (!trans.randomize() with { paddr == paddr_arg; data == data_arg; pwrite == 1; })
      $fatal(1, "APB-GEN: directed write randomization failed");
    tr = trans.do_copy();
    gen2driv.put(tr);
    $display("%0t [APB-GEN] Queued WRITE: addr=0x%0h data=0x%0h", $time(), paddr_arg, data_arg);
  endtask

  // Directed helper: queues a read transaction from the given address.
  task read_reg_transaction(bit [`ADDR_WIDTH-1:0] paddr_arg);
    if (!trans.randomize() with { paddr == paddr_arg; pwrite == 0; })
      $fatal(1, "APB-GEN: directed read randomization failed");
    tr = trans.do_copy();
    gen2driv.put(tr);
    $display("%0t [APB-GEN] Queued READ: addr=0x%0h", $time(), paddr_arg);
  endtask

endclass

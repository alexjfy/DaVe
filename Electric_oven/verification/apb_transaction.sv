// Data type used to transfer information between the generator and the driver.
// The monitor also captures data from the interface, reassembles it using this
// class, and forwards it for processing.
`include "defines.sv"

class apb_transaction;

  // Fields marked rand receive random values when randomize() is called.
  rand bit [`ADDR_WIDTH-1:0] paddr;
  rand bit                   pwrite;
  rand bit [`DATA_WIDTH-1:0] data;
  rand int                   delay;  // Clock cycles between two consecutive APB transactions

  // Constrain delay to a small positive range to keep simulation time reasonable.
  constraint delay_c { delay < 14; delay > 0; }

  // Restrict address to the three valid DUT register addresses: 0=temp, 1=mode, 2=timer.
  constraint valid_addr_c { paddr inside {0, 1, 2}; }

  // Called automatically after randomize(); logs the randomized field values.
  function void post_randomize();
    $display("%0t [TRANS] post_randomize: paddr=0x%0h  pwrite=%0b  data=0x%0h  delay=%0d",
             $time(), paddr, pwrite, data, delay);
  endfunction

  // Manual display for debugging — call explicitly when needed.
  function void display();
    $display("%0t [TRANS] APB transaction: paddr=0x%0h  pwrite=%0b  data=0x%0h  delay=%0d",
             $time(), paddr, pwrite, data, delay);
  endfunction

  // Deep copy — returns a new transaction object with the same field values.
  function apb_transaction do_copy();
    apb_transaction trans;
    trans = new();
    trans.paddr  = this.paddr;
    trans.pwrite = this.pwrite;
    trans.data   = this.data;
    trans.delay  = this.delay;
    return trans;
  endfunction

endclass

// Data type used to transfer door state between the generator, driver, and monitor.
// The monitor captures the door_closed signal from the interface and reconstructs
// a transaction object before forwarding it to the scoreboard.
class door_transaction;

  // Fields marked rand receive random values when randomize() is called.
  rand bit door_closed;

  // 90% probability door is closed (1), 10% probability door is open (0).
  // This models a realistic scenario where the door is usually closed during cooking.
  constraint door_closed_c { door_closed dist{1:=9, 0:=1}; }

  // Called automatically after randomize(); logs the randomized door state.
  function void post_randomize();
    $display("%0t [TRANS] post_randomize: door_closed=%0b", $time(), door_closed);
  endfunction

  // Deep copy — returns a new transaction object with the same field values.
  function door_transaction do_copy();
    door_transaction trans;
    trans = new();
    trans.door_closed = this.door_closed;
    return trans;
  endfunction

endclass

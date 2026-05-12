// Data type used by the LED monitor to capture and forward the LED output value.
// The LED has no driver or generator — it is purely an observed DUT output.
// The monitor samples the led signal each clock cycle and sends a transaction
// to the scoreboard for comparison against the predicted value.
class led_transaction;

  // Fields marked rand receive random values when randomize() is called.
  rand bit led;

  // Called automatically after randomize(); logs the LED value.
  function void post_randomize();
    $display("%0t [TRANS] post_randomize: led=%0b", $time(), led);
  endfunction

  // Deep copy — returns a new transaction object with the same field values.
  function led_transaction do_copy();
    led_transaction trans;
    trans = new();
    trans.led = this.led;
    return trans;
  endfunction

endclass


// This class declares the data type used to store data exchanged between
// generator and driver; the monitor also captures data from the interface,
// reconstructs it using an object of this type, and then processes it
class out_transaction;
  // Class attributes declaration
  // Fields declared with the rand keyword will receive random values when randomize() is applied

  rand bit wipers;
  rand bit high_beam;
  rand bit washer;
  rand bit flash;
  rand bit right_signal;
  rand bit left_signal;

  // Post-randomize callback: displays the randomized attribute values
  function void post_randomize();
    $display("[Trans] post_randomize: wipers=%0b high_beam=%0b washer=%0b flash=%0b l_sig=%0b r_sig=%0b",
             wipers, high_beam, washer, flash, left_signal, right_signal);
  endfunction

  // Deep copy operator
  function out_transaction do_copy();
    out_transaction trans;
    trans = new();
    trans.wipers = this.wipers;
    trans.high_beam = this.high_beam;
    trans.washer = this.washer;
    trans.flash = this.flash;
    trans.right_signal = this.right_signal;
    trans.left_signal = this.left_signal;
    return trans;
  endfunction
endclass


// This class declares the data type used to store data exchanged between
// generator and driver; the monitor also captures data from the interface,
// reconstructs it using an object of this type, and then processes it
class apb_transaction;
  // Class attributes declaration
  // Fields declared with the rand keyword will receive random values when randomize() is applied
  rand bit [ADDR_WIDTH-1:0] address;
  rand bit       write_enable; //1: write transaction; 0: read transaction
  rand bit [ DATA_WIDTH-1:0] data;
   rand int delay;
  int transaction_number;

  // Constraints are a type of class member in SystemVerilog, alongside attributes and methods
  // This constraint specifies that either a write or a read is executed
  // Constraints are applied by the compiler when class attributes receive random values via randomize()
  constraint delay_c { delay inside {[0:30]}; }; // between two APB transactions, wait 0 to 30 clock cycles

  // This function is called after randomize() is applied to objects of this class
  // It displays the randomized attribute values
  function void post_randomize();
    $display("[Trans] post_randomize: addr=0x%0h wr_en=%0h data=0x%0h delay=%0d trans_num=%0d",
             address, write_enable, data, delay, transaction_number);
  endfunction

  // Deep copy operator
  function apb_transaction do_copy();
    apb_transaction trans;
    trans = new();
    trans.address  = this.address;
    trans.write_enable = this.write_enable;
    trans.data = this.data;
    trans.delay = this.delay;
    trans.transaction_number =this.transaction_number;
    return trans;
  endfunction
endclass

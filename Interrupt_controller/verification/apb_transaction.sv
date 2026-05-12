//this declares the data type used to store data exchanged between generator and driver; the monitor also captures data from the interface, reconstructs it using an object of this data type, and only then processes it
typedef enum {APB_WRITE, APB_READ} apb_trans_kind_t;


class apb_transaction#(int AW=32, DW=32);
  //class attributes declaration
  //fields declared with the rand keyword will receive random values when the randomize() function is applied
  rand apb_trans_kind_t kind;
  rand bit [AW-1:0] addr;
  rand bit [DW-1:0] data;
  rand int unsigned delay;  // number of clock cycles between 2 transactions


  //constraints are a type of class member in SystemVerilog, alongside attributes and methods
  //this constraint specifies that either a write or a read is performed
  //constraints are applied by the compiler when class attributes receive random values through the randomize function
  constraint const_delay {delay inside {[5:20]};}
  //constraint data_mode {addr inside {[1:8]} -> data inside {[1:8]};}
  //constraint c_solve {solve addr before data;}

  //this function is called after applying randomize() on objects of this class
  //this function displays the randomized values of the class attributes
  function void post_randomize();
    $display("--------- [Trans] post_randomize ------");
    //$display("\t addr  = %0h",addr);
    if(kind == APB_WRITE) $display("Write: data = %0h\t address = %0h\t delay = %0h",data,addr, delay);
    if(kind == APB_READ) $display("Read: address = %0h\t delay = %0h",addr, delay);
    $display("-----------------------------------------");
  endfunction


   //deep copy operator — copies one object into another
  function apb_transaction do_copy();
    apb_transaction trans;
    trans = new();
    trans.addr  = this.addr;
    trans.data = this.data;
    trans.delay = this.delay;
    trans.kind = this.kind;
    return trans;
  endfunction
endclass
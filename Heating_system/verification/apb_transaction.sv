//-------------------------------------------------------------------------
//						www.verificationguide.com 
//-------------------------------------------------------------------------

//this data type stores data exchanged between generator and driver; the monitor also captures data from the interface, reconstructs it using this type, then processes it
class apb_transaction;
  //class attributes declaration
  //fields declared with the rand keyword receive random values when randomize() is called
  rand bit [ADDR_WIDTH-1:0] paddr;
  rand bit  pwrite; //1: write transaction; 0: read transaction
  rand bit [DATA_WIDTH-1:0] data;
  rand int delay;

  //constraints are a class member type in SystemVerilog, alongside attributes and methods
  //this constraint specifies that either a write or read is executed
  //constraints are applied by the compiler when class attributes receive random values via randomize()
  constraint delay_c {  delay<14; delay>0; }

  //this function is called after randomize() is applied to objects of this class
  //it displays the randomized attribute values
  function void post_randomize();
    $display("--------- [Trans] post_randomize ------");
    //$display("\t addr  = %0h",addr);
     $display("\t paddr  = %0h\t pwrite = %0h\t data = %0h",paddr,pwrite,data);
    $display("-----------------------------------------");
  endfunction
  
  //copy operator from one object to another (deep copy)
  function apb_transaction do_copy();
    apb_transaction trans;
    trans = new();
    trans.paddr  = this.paddr;
    trans.pwrite = this.pwrite;
    trans.data = this.data;
    return trans;
  endfunction
  
endclass
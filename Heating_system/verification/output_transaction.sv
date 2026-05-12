//-------------------------------------------------------------------------
//						www.verificationguide.com 
//-------------------------------------------------------------------------

//this data type stores data exchanged between generator and driver; the monitor also captures data from the interface, reconstructs it using this type, then processes it
class output_transaction;
  //class attributes declaration
  //fields declared with the rand keyword receive random values when randomize() is called
  rand bit unit_on;
  
  //constraints are a class member type in SystemVerilog, alongside attributes and methods
  //this constraint specifies that either a write or read is executed
  //constraints are applied by the compiler when class attributes receive random values via randomize()
 // constraint wr_rd_c { wr_en != rd_en; };

  //this function is called after randomize() is applied to objects of this class
  //it displays the randomized attribute values
  function void post_randomize();
    $display("--------- [Trans] post_randomize ------");
    //$display("\t addr  = %0h",addr);
    $display("\t unit_on  = %0h",unit_on);
    $display("-----------------------------------------");
  endfunction
  
  //copy operator from one object to another (deep copy)
  function output_transaction do_copy();
    output_transaction trans;
    trans = new();
    trans.unit_on  = this.unit_on;
    return trans;
  endfunction
endclass
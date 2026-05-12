//this declares the data type used to store data exchanged between generator and driver; the monitor also captures data from the interface, reconstructs it using an object of this data type, and only then processes it
class out_transaction;
  //class attributes declaration
  //fields declared with the rand keyword will receive random values when the randomize() function is applied
  rand bit [2:0] irq;


  //constraints are a type of class member in SystemVerilog, alongside attributes and methods
  //this constraint specifies that either a write or a read is performed
  //constraints are applied by the compiler when class attributes receive random values through the randomize function
  //constraint wr_rd_c { wr_en != rd_en; };

   //this function is called after applying randomize() on objects of this class
  //this function displays the randomized values of the class attributes
  function void post_randomize();
    $display("--------- [Trans] post_randomize ------");
    //$display("\t addr  = %0h",addr);
    $display("\t irq  = %0h",irq);
    $display("-----------------------------------------");
  endfunction

  //deep copy operator — copies one object into another
  function out_transaction do_copy();
    out_transaction trans;
    trans = new();
    trans.irq  = this.irq;

    return trans;
  endfunction
endclass
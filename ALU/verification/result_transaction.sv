//-------------------------------------------------------------------------
//						www.verificationguide.com 
//-------------------------------------------------------------------------

//This class declares the data type used to store result transaction data between monitor and scoreboard
class result_transaction;
  //Class attributes declaration
  //Fields declared with the rand keyword will receive random values when randomize() is called
  rand bit [15:0] result;

  //Constraints are a type of class member in SystemVerilog, alongside attributes and methods
  //This constraint specifies that either a write or a read is executed
  //Constraints are applied by the compiler when class attributes receive random values through randomize()
 // constraint wr_rd_c { wr_en != rd_en; };

  //This function is called after randomize() is applied to objects of this class
  //It displays the randomized values of the class attributes
  function void post_randomize();
    $display("--------- [Trans] post_randomize ------");
     $display("\t result  = %0h",result);
    $display("-----------------------------------------");
  endfunction
  
  //Deep copy operator — copies one object into another
  function result_transaction do_copy();
    result_transaction result_trans;
    result_trans = new();
    result_trans.result  = this.result;
    return result_trans;
  endfunction
endclass
//-------------------------------------------------------------------------
//						www.verificationguide.com 
//-------------------------------------------------------------------------

//This class declares the data type used to store data exchanged between generator and driver;
//the monitor also captures data from the interface, reconstructs it using an object of this type, and then processes it
parameter DATA_WIDTH = 32;
class transactionAPB;
  //Class attributes declaration
  //Fields declared with the rand keyword will receive random values when randomize() is called

  rand bit 		   write ;
  rand bit [31:0]  data  ;
  rand bit [4:0]   addr  ;
  rand int unsigned	   delay ;
  	   bit       slaveRsp;

  //Constraints are a type of class member in SystemVerilog, alongside attributes and methods
  //This constraint specifies that either a write or a read is executed
  //Constraints are applied by the compiler when class attributes receive random values through randomize()
///  constraint delay_c {delay inside {[0:20]};}
  //This function is called after randomize() is applied to objects of this class
  //It displays the randomized values of the class attributes
  function void post_randomize();
    $display("--------- [Trans] post_randomize ------");
    //$display("\t addr  = %0h",addr);
    $display("\t addr  = %0h\t write = %0h\t data = %0h delay = %0d\t",addr,write,data, delay);
    $display("-----------------------------------------");
  endfunction
  
  //Deep copy operator — copies one object into another
  function transactionAPB do_copyAPB();
    transactionAPB trans;
    trans = new();
    trans.write    = this.write;
    trans.data     = this.data;
    trans.delay    = this.delay;
    trans.addr 	   = this.addr;
    trans.slaveRsp = this.slaveRsp;
//     trans.addr  = this.addr;
//     trans.wr_en = this.wr_en;
//     trans.rd_en = this.rd_en;
//     trans.wdata = this.wdata;
    return trans;
  endfunction
endclass
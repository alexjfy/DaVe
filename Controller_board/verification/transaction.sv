
// This class declares the data type used to store data exchanged between
// generator and driver; the monitor also captures data from the interface,
// reconstructs it using an object of this type, and then processes it
class transaction;
  // Class attributes declaration
  // Fields declared with the rand keyword will receive random values when randomize() is applied
  rand bit [1:0] addr;
  rand bit       wr_en;
  rand bit       rd_en;
  rand bit [7:0] wdata;
       bit [7:0] rdata;
       bit [1:0] cnt;

  // Constraints are a type of class member in SystemVerilog, alongside attributes and methods
  // This constraint specifies that either a write or a read is executed
  // Constraints are applied by the compiler when class attributes receive random values via randomize()
  constraint wr_rd_c { wr_en != rd_en; };

  // This function is called after randomize() is applied to objects of this class
  // It displays the randomized attribute values
  function void post_randomize();
    if(wr_en) $display("[Trans] post_randomize: addr=0x%0h wr_en=%0h wdata=0x%0h", addr, wr_en, wdata);
    if(rd_en) $display("[Trans] post_randomize: addr=0x%0h rd_en=%0h", addr, rd_en);
  endfunction

  // Deep copy operator
  function transaction do_copy();
    transaction trans;
    trans = new();
    trans.addr  = this.addr;
    trans.wr_en = this.wr_en;
    trans.rd_en = this.rd_en;
    trans.wdata = this.wdata;
    return trans;
  endfunction
endclass

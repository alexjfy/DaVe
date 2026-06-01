`ifndef __button_transaction
`define __button_transaction

class button_transaction extends uvm_sequence_item;
  
  rand bit enable;

  //add transaction to the UVM database
  `uvm_object_utils_begin(button_transaction)
    `uvm_field_int(enable, UVM_ALL_ON)
  `uvm_object_utils_end

  //declare the class constructor;
  function new(string name = "button_transaction");
    super.new(name);
  	enable = 0;
  endfunction
  
endclass : button_transaction

`endif
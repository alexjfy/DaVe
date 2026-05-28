`ifndef __button_transaction
`define __button_transaction
typedef enum {UNPUSHED_BUTTON, SHORT_PUSH_BUTTON, LONG_PUSH_BUTTON} button_state;

class button_transaction extends uvm_sequence_item;
  
  rand button_state button;
  
  //add transaction to the UVM database
  `uvm_object_utils_begin(button_transaction)
    `uvm_field_enum(button_state, button, UVM_ALL_ON)
  `uvm_object_utils_end
 
  //declare the class constructor;
  function new(string name = "button_transaction");
    super.new(name);
  	button = UNPUSHED_BUTTON;
  endfunction

endclass : button_transaction

`endif
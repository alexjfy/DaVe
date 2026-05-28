`ifndef __lamp_transaction
`define __lamp_transaction
typedef enum {LIGHT_OFF, ON_LEVEL_0, ON_LEVEL_1, ON_LEVEL_2} lamp_state;

class lamp_transaction extends uvm_sequence_item;
  
  rand lamp_state light_level_out;
  
  //add transaction to the UVM database
  `uvm_object_utils_begin(lamp_transaction)
    `uvm_field_enum(lamp_state, light_level_out, UVM_ALL_ON)
  `uvm_object_utils_end
  
  //declare the class constructor;
  function new(string name = "lamp_transaction");
    super.new(name);
  	light_level_out = LIGHT_OFF;
  endfunction

endclass : lamp_transaction

`endif
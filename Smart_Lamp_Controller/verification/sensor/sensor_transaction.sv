`ifndef __sensor_transaction
`define __sensor_transaction

class sensor_transaction extends uvm_sequence_item;
  
  rand bit [7:0] sensor;
  
  //add transaction to the UVM database
  `uvm_object_utils_begin(sensor_transaction)
    `uvm_field_int(sensor, UVM_ALL_ON)
  `uvm_object_utils_end
 
  //declare the class constructor;
  function new(string name = "sensor_transaction");
    super.new(name);
  	sensor = 0;
  endfunction

endclass : sensor_transaction

`endif
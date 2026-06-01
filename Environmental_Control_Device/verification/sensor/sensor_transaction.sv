`ifndef __sensor_transaction
`define __sensor_transaction

class sensor_transaction extends uvm_sequence_item;
  
  rand bit[5:0] temperature;
  rand bit[6:0] humidity;
  rand bit[9:0] luminous_intensity;
  
  //add transaction to the UVM database
  `uvm_object_utils_begin(sensor_transaction)
    `uvm_field_int(temperature, UVM_ALL_ON)
    `uvm_field_int(humidity, UVM_ALL_ON)
    `uvm_field_int(luminous_intensity, UVM_ALL_ON)
  `uvm_object_utils_end

  constraint temperature_c        {temperature 	      inside {[0:40]};}
  constraint humidity_c           {humidity 		      inside {[0:100]};}
  constraint luminous_intensity_c {luminous_intensity inside {[0:900]};}
  
  //declare the class constructor;
  function new(string name = "sensor_transaction");
    super.new(name);  
    temperature = 23;
  	humidity = 0;
  	luminous_intensity = 0;
  endfunction

endclass : sensor_transaction

`endif
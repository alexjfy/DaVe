`ifndef __global_coverage
`define __global_coverage

class global_coverage extends uvm_component;
  
  //the component is added to the database of this project;
  `uvm_component_utils(global_coverage)
  
  //declare pointer to the scoreboard
  scoreboard p_scoreboard;
  
  covergroup processed_data_cg;
    option.per_instance = 1;
    scbd_enable_cp: coverpoint p_scoreboard.enable;
    scbd_temperature_cp: coverpoint p_scoreboard.sensor_trans.temperature{
      option.weight = 0;
      bins range[5] = {[0:40]};
    }
    scbd_humidity_cp: coverpoint p_scoreboard.sensor_trans.humidity{
      option.weight = 0;
      bins range[5] = {[0:100]};
    }
    scbd_luminous_intensity_cp: coverpoint p_scoreboard.sensor_trans.luminous_intensity{
      option.weight = 0;
      bins range[5] = {[0:900]};
    }
    
    //cover processed data when enable is 1
    temperature_cross: cross scbd_enable_cp, scbd_temperature_cp{
      ignore_bins ignore_disabled_module_values = temperature_cross with (scbd_enable_cp == 0);
    }
    humidity_cross: cross scbd_enable_cp, scbd_humidity_cp{
       ignore_bins ignore_disabled_module_values = humidity_cross with (scbd_enable_cp == 0);
    }
    luminous_intensity_cross: cross scbd_enable_cp, scbd_luminous_intensity_cp{
       ignore_bins ignore_disabled_module_values = luminous_intensity_cross with (scbd_enable_cp == 0);
    }
  endgroup
  
  //declare the class constructor;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    $cast(p_scoreboard, parent);
    processed_data_cg = new();
  endfunction
  
endclass

`endif
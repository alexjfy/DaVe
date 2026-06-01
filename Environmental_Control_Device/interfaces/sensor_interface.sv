`ifndef __sensor_intf
`define __sensor_intf

interface sensor_interface;
  logic       clk_i; 
  logic       reset_i;
  logic [9:0] luminous_intensity_i;
  logic [5:0] temperature_i;
  logic [6:0] humidity_i;
  logic       valid_i;
  logic       ready_o;
  

  // Assertions

  // temperature must be in the interval [0,40]
  property temperature_range;
    @(posedge clk_i) disable iff (reset_i==1)
    temperature_i >= 0 && temperature_i <= 40;
  endproperty
  
  temperature_range_assertion: assert property (temperature_range) 
    else `uvm_error("SENSOR_INTERFACE", $sformatf("temperature_range_assertion failed: temperature_i = %0d", temperature_i));
  TEMPERATURE_RANGE: cover property (temperature_range);

  // humidity must be in the interval [0,100]     
  property humidity_range;
     @(posedge clk_i) disable iff (reset_i==1)
        humidity_i >= 0 && humidity_i <= 100;
  endproperty
  
  humidity_range_assertion: assert property (humidity_range) 
    else `uvm_error("SENSOR_INTERFACE", $sformatf("humidity_range_assertion failed: humidity_i = %0d", humidity_i));
  HUMIDITY_RANGE: cover property (humidity_range);
      
  // luminous intensity must be in the interval [0,900]         
  property luminous_intensity_range;
    @(posedge clk_i) disable iff (reset_i==1)
    luminous_intensity_i >= 0 && luminous_intensity_i <= 900;
  endproperty
  
  luminous_intensity_range_assertion: assert property (luminous_intensity_range) 
    else `uvm_error("SENSOR_INTERFACE", $sformatf("luminous_intensity_range_assertion failed: luminous_intensity_i = %0d", luminous_intensity_i));
  LUMINOUS_INTENSITY_RANGE: cover property (luminous_intensity_range);
      
endinterface

`endif
`ifndef __sensor_intf
`define __sensor_intf

interface sensor_interface;
  logic       clk; 
  logic       rst;
  logic [7:0] brightness;
  logic       ready; 
  logic       valid;
  
  //assertions
	//valid must be 1 if ready is 1
  //exeption: when ready toggles from 1 to 0
  property valid_ready;
    @(posedge clk) disable iff (rst==0)
    (valid == 1 |-> ready == 1 or $fell(ready));
  endproperty
  
  valid_ready_assertion: assert property (valid_ready) 
    else `uvm_error("SENSOR_INTERFACE", "valid_ready_assertion failed");
  VALID_READY: cover property (valid_ready); //check if the property was covered at least once
      
  //valid must be a single pulse
  property valid_puls;
    @(posedge clk) disable iff (rst==0)
    (valid == 1 |=> valid == 0);
  endproperty
  
  valid_puls_assertion: assert property (valid_puls) 
    else `uvm_error("SENSOR_INTERFACE", "valid_puls_assertion failed");
  VALID_PULS: cover property (valid_puls);

endinterface

`endif

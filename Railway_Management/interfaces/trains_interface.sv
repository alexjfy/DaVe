`ifndef __trains_interface
`define __trains_interface

interface trains_interface;
  logic clk; 
  logic rst;
  logic t_1;
  logic t_2;
  logic t_3;
  logic t_4;
  logic t_5;
  logic t_6;
  
  // Assertions
    // 
  // property requests_less_than_two;
  //   @(posedge clk) disable iff (rst==1)
  //   (t_1 + t_2 + t_3 + t_4 + t_5 + t_6 <=2);
  // endproperty
  
  // requests_less_than_two_assertion: assert property (requests_less_than_two);
  //   REQUESTS_LESS_THAN_TWO: cover property (requests_less_than_two);
      
  //   //   
  // property t1_and_break;
  //   @(posedge clk) disable iff (rst==1)
  //   t_1 |=> ##[0:2] !t_1;
  // endproperty
  
  // t1_and_break_assertion: assert property (t1_and_break);
  //   T1_AND_BREAK: cover property (t1_and_break);
endinterface

`endif

/* Protocol diagram
 * reset (not represented) is active high
 * t_(1..6) indicates that the train (1..6) requested to enter the high interest line section
        __    __    __    __    __    __    __    __    __    __    __    __    __    __   
clk____|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__
              _____             _____                         _____                        
t_1__________|     |___________|     |_______________________|     |_______________________
                    _____                   _____                         _____            
t_2________________|     |_________________|     |_______________________|     |___________
                                _____             _____                         _____      
t_3____________________________|     |___________|     |_______________________|     |_____
        _____                   _____                         _____                        
t_4____|     |_________________|     |_______________________|     |_______________________
              _____             _____                                                      
t_5__________|     |___________|     |_____________________________________________________
              _____             _____                         _____                        
t_6__________|     |___________|     |_______________________|     |_______________________
  
 */
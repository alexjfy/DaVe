// `define DEBUG 

`include "uvm_macros.svh"
import uvm_pkg::*;

typedef enum {NT,T1,T2,T3,T4,T5,T6} railway_state;

module railway_management(
input clk_i,
input reset_i,
input t1_i,
input t2_i,
input t3_i,
input t4_i,
input t5_i,
input t6_i,
output reg odd_semaphore_o,
output reg even_semaphore_o);
  
  railway_state current_state, next_state ;
  
  //traffic lights are declared as internal signals to allow both read and write access
  reg even_semaphore_s, odd_semaphore_s = 0;
  logic [5:0] trains_req, valid_trains_req, even_mask, odd_mask;
  
  //create a vector with all incoming train requests
  assign trains_req = {t1_i, t3_i, t5_i, t2_i, t4_i, t6_i};
  
  //filter train requests invalidated by semaphore colors; only requests for trains with a green light at the addressed semaphore remain valid (first term of the mask)
  assign valid_trains_req = trains_req & {~odd_semaphore_s , ~odd_semaphore_s, ~odd_semaphore_s, ~even_semaphore_s, ~even_semaphore_s, ~even_semaphore_s};
  
  //find the highest priority valid request
  always @(valid_trains_req or posedge clk_i) begin
    //check that winner train doesn't win next cycle
    `ifdef DEBUG
    $display("%t unmasked states %b", $time(), trains_req);
    $display("%t masked states %b", $time(), valid_trains_req);
    `endif
    if (valid_trains_req[5] == 1 && current_state != T1 ) begin
      next_state <= T1;
      `ifdef DEBUG
        $display("DUT: %t, starea viitoare: T1", $time());
      `endif
    end else if (valid_trains_req[4] == 1 && current_state != T3) begin
      next_state <= T3;
      `ifdef DEBUG
        $display("DUT: %t, starea viitoare: T3", $time());
      `endif
    end else if (valid_trains_req[3] == 1 && current_state != T5) begin
      next_state <= T5;
      `ifdef DEBUG
        $display("DUT: %t, starea viitoare: T5", $time());
      `endif
    end else if (valid_trains_req[2] == 1 && current_state != T2) begin
      next_state <= T2;
      `ifdef DEBUG
        $display("DUT: %t, starea viitoare: T2", $time());
      `endif
    end else if (valid_trains_req[1] == 1 && current_state != T4) begin
      next_state <= T4;
      `ifdef DEBUG
        $display("DUT: %t, starea viitoare: T4", $time());
      `endif
    end else if (valid_trains_req[0] == 1 && current_state != T6) begin
      next_state <= T6;
      `ifdef DEBUG
        $display(" DUT: %t, starea viitoare: T6", $time());
      `endif
    end else begin
      next_state <= NT;
      `ifdef DEBUG
        $display("DUT: %t, starea viitoare: NT", $time());
      `endif
    end
  end
  
  always @(negedge clk_i or posedge reset_i)
    if (reset_i == 1)
      current_state <= NT;
    else
      current_state <= current_state == next_state ? NT : next_state; //railway state shouldn't be the same two consecutive cycles
  
  always @(negedge clk_i or posedge reset_i)
    if (reset_i == 1) begin
      odd_semaphore_s <= 0;
      even_semaphore_s <= 0; 
    end else if (current_state == next_state) begin
      odd_semaphore_s <= 0;
      even_semaphore_s <= 0; 
    end else if (next_state == T1 || next_state == T3 || next_state == T5) begin
      odd_semaphore_s <= 0;
      even_semaphore_s <= 1; 
    end else if (next_state == T2 || next_state == T4 || next_state == T6) begin
      odd_semaphore_s <= 1;
      even_semaphore_s <= 0; 
    end else begin //NT state
      odd_semaphore_s <= 0;
      even_semaphore_s <= 0; 
    end
  
  //internal signals are sent to output
  assign odd_semaphore_o = odd_semaphore_s;
  assign even_semaphore_o = even_semaphore_s;
        
endmodule
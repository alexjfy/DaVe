`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __railway_state_coverage
`define __railway_state_coverage

`include "defines.sv"

class railway_state_coverage extends uvm_component;
  
  //the component is added to the database of this project;
  `uvm_component_utils(railway_state_coverage)
  
  //declare pointer to the scoreboard
  scoreboard p_scoreboard;
  
  covergroup fsm_cg;
    option.per_instance = 1;
    current_state : coverpoint p_scoreboard.current_state;
    next_state : coverpoint p_scoreboard.next_state;

    state_transition : cross current_state, next_state{
      // From odd states, direct transitions only to odd states or NT
      ignore_bins odd_to_even = binsof(current_state) intersect {TRAIN1, TRAIN3, TRAIN5} &&
                                binsof(next_state) intersect {TRAIN2, TRAIN4, TRAIN6};
      // From even states, direct transitions only to even states or NT
      ignore_bins even_to_odd = binsof(current_state) intersect {TRAIN2, TRAIN4, TRAIN6} &&
                                binsof(next_state) intersect {TRAIN1, TRAIN3, TRAIN5};
      // Same train twice consecutively is invalid
      ignore_bins same_train =
        // binsof(current_state) intersect {TRAIN1, TRAIN2, TRAIN3, TRAIN4, TRAIN5, TRAIN6} &&
        // binsof(next_state) intersect {TRAIN1, TRAIN2, TRAIN3, TRAIN4, TRAIN5, TRAIN6} &&
        binsof(current_state) == binsof(next_state);
    }
  endgroup
  
  //declare the class constructor;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    $cast(p_scoreboard, parent);
    fsm_cg = new();
  endfunction
  
endclass : railway_state_coverage

`endif
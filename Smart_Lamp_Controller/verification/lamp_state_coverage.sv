`ifndef __lamp_state_coverage
`define __lamp_state_coverage

class lamp_state_coverage extends uvm_component;
  
  //the component is added to the database of this project;
  `uvm_component_utils(lamp_state_coverage)
  
  //declare pointer to the scoreboard
  scoreboard p_scoreboard;
  
  covergroup lamp_transition_coverage_cg;
    option.per_instance = 1;
    // cover all lamp states
    current_lamp_state: coverpoint p_scoreboard.current_lamp_state;
    next_lamp_state   : coverpoint p_scoreboard.next_lamp_state;
    // cover all lamp modes
    current_mode: coverpoint p_scoreboard.current_mode;
    next_mode   : coverpoint p_scoreboard.next_mode;

    // cover all transitions between lamp states
    lamp_transition : cross current_lamp_state, next_lamp_state;
    // cover all transitions between lamp modes
    operation_transition : cross current_mode, next_mode{
      ignore_bins invalid_to_off = binsof(current_mode) intersect {OFF, MANUAL} && 
                                             binsof(next_mode) intersect {OFF};
    }
    // cover all transitions between lamp states in both modes
    lamp_operation_transition : cross current_lamp_state, next_lamp_state, current_mode{
      // In OFF mode there are no lamp state transitions
      ignore_bins off_mode_transitions = binsof(current_mode) intersect {OFF};
      // In MANUAL mode, transitions are succesive
      ignore_bins manual_invalid_light_off = binsof(current_mode) intersect {MANUAL} && 
                                             binsof(current_lamp_state) intersect {LIGHT_OFF} &&
                                             binsof(next_lamp_state) intersect {ON_LEVEL_1, ON_LEVEL_2, LIGHT_OFF};
      ignore_bins manual_invalid_on_level_0 = binsof(current_mode) intersect {MANUAL} &&
                                              binsof(current_lamp_state) intersect {ON_LEVEL_0} &&
                                              binsof(next_lamp_state) intersect {ON_LEVEL_0, ON_LEVEL_2, LIGHT_OFF};
      ignore_bins manual_invalid_on_level_1 = binsof(current_mode) intersect {MANUAL} &&
                                              binsof(current_lamp_state) intersect {ON_LEVEL_1} &&
                                              binsof(next_lamp_state) intersect {ON_LEVEL_1, LIGHT_OFF, ON_LEVEL_0};
      ignore_bins manual_invalid_on_level_2 = binsof(current_mode) intersect {MANUAL} &&
                                              binsof(current_lamp_state) intersect {ON_LEVEL_2} &&
                                              binsof(next_lamp_state) intersect {ON_LEVEL_2, ON_LEVEL_0, ON_LEVEL_1};
    }
  endgroup
  
  //declare the class constructor;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    $cast(p_scoreboard, parent);
    lamp_transition_coverage_cg = new();
  endfunction
  
endclass

`endif
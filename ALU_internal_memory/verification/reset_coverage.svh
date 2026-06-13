// Module name: reset_coverage
// HDL        : UVM
// Description: Functional coverage for the reset interface. One bin per
//              observed value of reset_n and state so we confirm that both
//              levels are exercised during the test suite.
class reset_coverage extends uvm_subscriber #(reset_item);

  `uvm_component_utils(reset_coverage)

  function new(string name="reset_coverage",uvm_component parent);
    super.new(name,parent);
    cov_reset_n =new();
    cov_state =new();
  endfunction
  
  reset_item item_reset     ;
  real reset_n_cov           ;
  real state_cov           ;
  
  // reset_n value covergroup (only the active-low edge is sampled)
  covergroup cov_reset_n;
  RESET_N: coverpoint item_reset.reset_n {
    bins interval0 = {'b0};
    // bins interval1 = {'b1};
  }
  endgroup

  covergroup cov_state;
  STATE: coverpoint item_reset.state  {
    bins interval0 = {'b0};
    // bins interval1 = {'b1};
  }
  endgroup

  function void write(reset_item t);
    item_reset = t;
    cov_reset_n.sample();
    cov_state.sample();
  endfunction

  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    reset_n_cov=cov_reset_n.get_coverage();
    state_cov=cov_state.get_coverage();
  endfunction


  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),$sformatf("Reset Interface : Coverage for Reset_n is %f",reset_n_cov),UVM_MEDIUM)
    `uvm_info(get_type_name(),$sformatf("Reset Interface : Coverage for State   is %f",state_cov),UVM_MEDIUM)
  endfunction 

endclass : reset_coverage
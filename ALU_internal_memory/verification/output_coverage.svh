// Module name: output_coverage
// HDL        : UVM
// Description: Functional coverage for the ALU result bus. Slices the 9-bit
//              result space into 10 equal intervals so that every magnitude
//              band is exercised by the test suite.
class output_coverage extends uvm_subscriber #(output_item);

  `uvm_component_utils(output_coverage)

  function new(string name="output_coverage",uvm_component parent);
    super.new(name,parent);
    cov_result =new();
  endfunction
  
  output_item item_result     ;
  real result_cov           ;
  
  // Result value covergroup: ten equally-sized bins across the 9-bit space
  covergroup cov_result;
  RESULT: coverpoint item_result.result  {
    bins interval[10] = {['d0 : $]};
  }
  endgroup

  function void write(output_item t);
    item_result = t;
    cov_result.sample();
  endfunction

  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    result_cov=cov_result.get_coverage();
  endfunction


  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(),$sformatf("Output Interface : Coverage for result is %f",result_cov),UVM_MEDIUM)
  endfunction 

endclass : output_coverage
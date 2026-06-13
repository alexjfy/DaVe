// Module name: output_item
// HDL        : UVM
// Description: Transaction emitted by the output monitor each time the ALU
//              result bus is captured. Carries only the 9-bit result field.
class  output_item extends uvm_sequence_item;

  bit [8:0] result ;

  `uvm_object_utils_begin(output_item)
    `uvm_field_int (result ,      UVM_DEFAULT)
  `uvm_object_utils_end
                     
  function new (string name = "output_item");
    super.new(name);
  endfunction

endclass
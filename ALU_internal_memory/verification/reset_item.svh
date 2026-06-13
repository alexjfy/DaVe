// Module name: reset_item
// HDL        : UVM
// Description: Transaction used by the reset sequencer and monitor. Carries
//              the target value of reset_n and the run/freeze state bit.
class reset_item extends uvm_sequence_item;

  bit reset_n;
  bit state;

  `uvm_object_utils_begin(reset_item)
    `uvm_field_int (reset_n,      UVM_DEFAULT)
    `uvm_field_int (state,      UVM_DEFAULT)
  `uvm_object_utils_end
                     
  function new (string name = "reset_item");
    super.new(name);
  endfunction
endclass
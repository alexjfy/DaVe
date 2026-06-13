// Module name: reset_sequencer
// HDL        : UVM
// Description: Reset-domain sequencer. Forwards reset_item transactions from
//              the running sequence to the reset driver.
class reset_sequencer extends uvm_sequencer #(reset_item);

  `uvm_component_utils(reset_sequencer)

  function new(string name, uvm_component parent);
    super.new (name, parent);
  endfunction

endclass
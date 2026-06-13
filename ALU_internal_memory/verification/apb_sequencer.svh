// Module name: apb_sequencer
// HDL        : UVM
// Description: Parameterised APB sequencer. Feeds apb_item requests to the
//              driver and forwards the response objects back to the running
//              sequence via the standard put_response mechanism.
class apb_sequencer extends uvm_sequencer #(apb_item, apb_item);

  `uvm_component_utils(apb_sequencer)

  function new(string name, uvm_component parent);
    super.new (name, parent);
  endfunction

endclass

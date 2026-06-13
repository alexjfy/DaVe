// Module name: reset_agent
// HDL        : UVM
// Description: Reset agent. When active, builds driver and sequencer and
//              connects them; the monitor is instantiated in both active and
//              passive modes.
class reset_agent extends uvm_agent;

  `uvm_component_utils(reset_agent)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  reset_driver          drv_reset;
  reset_monitor         mon_reset;
  reset_sequencer       seq_reset;

  virtual function void build_phase(uvm_phase phase);
   if(get_is_active())
    begin
      seq_reset = reset_sequencer::type_id::create ("seq_reset", this);
      drv_reset = reset_driver::type_id::create ("drv_reset", this);
    end
  mon_reset = reset_monitor::type_id::create ("mon_reset", this);
  endfunction

  virtual function void connect_phase (uvm_phase phase);
   if(get_is_active())
  drv_reset.seq_item_port.connect (seq_reset.seq_item_export);
  endfunction

endclass
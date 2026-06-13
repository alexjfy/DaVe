// Module name: apb_agent
// HDL        : UVM
// Description: APB agent. When active, instantiates driver, monitor and
//              sequencer and connects the sequencer to the driver. When
//              passive, only the monitor is built.
class apb_agent extends uvm_agent;

  `uvm_component_utils(apb_agent)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  apb_driver            drv_apb;
  apb_monitor           mon_apb;
  apb_sequencer         seq_apb;

  virtual function void build_phase(uvm_phase phase);
   if(get_is_active())
      begin
        seq_apb = apb_sequencer::type_id::create ("seq_apb", this);
        drv_apb = apb_driver::type_id::create ("drv_apb", this);
      end
    mon_apb = apb_monitor::type_id::create ("mon_apb", this);
  endfunction

  virtual function void connect_phase (uvm_phase phase);
   if(get_is_active())
      drv_apb.seq_item_port.connect (seq_apb.seq_item_export);
  endfunction


endclass
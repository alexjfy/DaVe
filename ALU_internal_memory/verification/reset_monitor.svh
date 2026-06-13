// Module name: reset_monitor
// HDL        : UVM
// Description: Passive monitor that watches reset_n and the state bit and
//              fires a reset_item on the analysis port each time the DUT
//              comes out of reset.
class reset_monitor extends uvm_monitor ;

  `uvm_component_utils (reset_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual reset_interface vif_reset;
  uvm_analysis_port #(reset_item) mon_analysis_port_reset;

  function void build_phase(uvm_phase phase); 
    super.build_phase (phase);
    mon_analysis_port_reset = new ("mon_analysis_port_reset", this);
    if(! uvm_config_db #(virtual reset_interface) :: get (this , "", "vif_reset", vif_reset)) begin
      `uvm_error (get_type_name (), "Not found")
    end
  endfunction

  task run_phase(uvm_phase phase);
    reset_item data_mon_reset = reset_item::type_id::create ("data_mon_reset", this);
    forever begin
      @(posedge vif_reset.state);
      @(negedge vif_reset.reset_n);
      @(posedge vif_reset.reset_n);
      mon_analysis_port_reset.write(data_mon_reset);
      `uvm_info (get_type_name(), $sformatf ("The data from reset monitor was received!"), UVM_NONE)
    end
  endtask

endclass
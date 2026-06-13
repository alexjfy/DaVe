// Module name: reset_driver
// HDL        : UVM
// Description: Drives reset_n and the run/freeze state bit onto vif_reset
//              based on reset_item transactions produced by the reset
//              sequencer.
class reset_driver extends uvm_driver #(reset_item);
  `uvm_component_utils(reset_driver)
  function new(string name, uvm_component parent);
    super.new (name, parent);
  endfunction

  virtual reset_interface vif_reset;
  reset_item data_project_reset;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
      if(!uvm_config_db #(virtual reset_interface) :: get ( this, "", "vif_reset", vif_reset)) begin
        `uvm_fatal (get_type_name (), "Didn't get handle to virtual interface")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
  	forever begin 
    	seq_item_port.get_next_item(data_project_reset);
    	$display("%s" , data_project_reset.sprint());
      vif_reset.reset_n <= data_project_reset.reset_n;
      vif_reset.state   <= data_project_reset.state;
  	  seq_item_port.item_done();
      `uvm_info (get_type_name(), $sformatf ("Reset complete."), UVM_NONE)
  	end
  endtask
endclass

// Module name: apb_monitor
// HDL        : UVM
// Description: Passive monitor that samples the APB bus and produces apb_item
//              transactions for the scoreboard and the coverage collector.
//              Also measures the idle delay (in clocks) between two
//              consecutive transactions.
class apb_monitor extends uvm_monitor ;
  `uvm_component_utils (apb_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Handles
  virtual apb_interface           vif_apb;
  apb_item                        delay_mon;
  bit [31:0]                      delay;
  uvm_analysis_port #(apb_item)   mon_analysis_port_apb;

  function void build_phase(uvm_phase phase);
    super.build_phase (phase);
    mon_analysis_port_apb = new ("mon_analysis_port_apb", this);
    if(! uvm_config_db #(virtual apb_interface) :: get (this , "", "vif_apb", vif_apb)) begin
      `uvm_error (get_type_name (), "Not found")
    end
  endfunction

  task run_phase(uvm_phase phase);
    apb_item data_mon = apb_item::type_id::create ("data_mon", this);

    // Background task counting clocks between two active PSEL windows
    fork
      count_delay();
    join_none

    forever begin
      // Wait for a complete APB transfer (psel & penable & pready)
      @(vif_apb.cb_monitor_apb iff vif_apb.cb_monitor_apb.psel && vif_apb.cb_monitor_apb.penable && vif_apb.cb_monitor_apb.pready );
      data_mon.pwrite      = vif_apb.cb_monitor_apb.pwrite;
      data_mon.delay_psel  = delay;  // inter-transaction idle time captured by count_delay
      delay                = 0;      // reset delay counter for the next transaction
      if (vif_apb.cb_monitor_apb.pwrite == 1) begin
        // Write: capture pwdata and the target address
        data_mon.pwdata = vif_apb.cb_monitor_apb.pwdata;
        `uvm_info (get_type_name(), $sformatf ("The pwdata is receive with value = %b",data_mon.pwdata), UVM_NONE)
        data_mon.paddr  = vif_apb.cb_monitor_apb.paddr;
      end else if (vif_apb.cb_monitor_apb.pwrite == 0) begin
        // Read: capture prdata returned by the DUT and the source address
        data_mon.prdata = vif_apb.cb_monitor_apb.prdata;
        data_mon.paddr  = vif_apb.cb_monitor_apb.paddr;
      end
      `uvm_info (get_type_name(), $sformatf ("The data from monitor was received!"), UVM_NONE)
      mon_analysis_port_apb.write(data_mon);
      $display("%s" , data_mon.sprint());
    end
  endtask

  // Counts the number of clock cycles while PSEL is low. The resulting
  // value is stamped on the next observed transaction as delay_psel.
  task count_delay ();
    forever begin
      @(vif_apb.cb_monitor_apb ) if(vif_apb.cb_monitor_apb.psel == 0)  delay = delay + 1;
    end
  endtask

endclass

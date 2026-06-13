`ifndef APB_AGENT_SV
`define APB_AGENT_SV

class apb_agent extends uvm_agent;

  `uvm_component_utils(apb_agent)

  apb_driver                  apb_drv;
  uvm_sequencer #(apb_trans)  apb_seqr;
  apb_monitor                 apb_mon;
  apb_coverage                apb_cov;
 
  local bit is_active = 1;      // 0 = passive agent; 1 = active agent
  local bit has_coverage = 1;   // 0 = no coverage; 1 = with coverage

  function new(string name = "apb_agent", uvm_component parent);
    super.new(name, parent);
  endfunction:new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    apb_mon = apb_monitor::type_id::create("apb_mon", this);

    if(is_active == UVM_ACTIVE) begin
      apb_drv  = apb_driver::type_id::create("apb_drv", this);
      apb_seqr = uvm_sequencer#(apb_trans)::type_id::create("apb_seqr", this);
    end

    if(has_coverage) begin
      apb_cov  = apb_coverage::type_id::create("apb_cov", this);
    end

  endfunction:build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    if (is_active == UVM_ACTIVE) begin
      apb_drv.seq_item_port.connect(apb_seqr.seq_item_export);
    end
    if (has_coverage) begin
		  apb_mon.apb_port.connect(apb_cov.analysis_export);
    end
  endfunction:connect_phase
  
endclass:apb_agent

`endif
`ifndef TEST_REGISTERS_SV
`define TEST_REGISTERS_SV


`include "environment.sv"
`include "apb_seq_lib.sv"

// Runs registers_seq: reads default values, writes all registers,
// then reads them back to check write/read behavior per register
class test_registers extends test_base;

  `uvm_component_utils(test_registers)

  registers_seq apb_registers_seq;


  function new(string name="test_registers", uvm_component parent);
    super.new(name, parent);
  endfunction:new


  virtual function void build_phase(uvm_phase phase);
  // Build the environment and create the register sequence
    env = environment::type_id::create("env", this);
    apb_registers_seq =  registers_seq::type_id::create("apb_registers_seq");

    `uvm_info(get_type_name(), $sformatf("Start test_registers"), UVM_LOW)
  endfunction:build_phase

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info("TEST_REGISTER", "real execution begins", UVM_NONE);
      begin
     `ifdef DEBUG
        $display("Starting register sequence for the active agent");
      `endif;
     	apb_registers_seq.start(env.apb_mst_agnt.apb_seqr);
      `ifdef DEBUG
        $display("Sequence execution completed for the active agent");
      `endif;
      end

    #10000
    phase.drop_objection(this);
    endtask

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction:end_of_elaboration_phase

endclass:test_registers


`endif

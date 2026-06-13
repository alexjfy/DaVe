`ifndef TEST_FUNCTIONAL_SV
`define TEST_FUNCTIONAL_SV


`include "environment.sv"
`include "apb_seq_lib.sv"

// Configures CONFIG (channels on, sensor enabled) and writes random
// seeds, triggering full I2C transfers; checks coverage and verdict
class test_functional extends test_base;

  `uvm_component_utils(test_functional)

  apb_5_packets apb_5_packets_seq;
  color_disable_seq apb_color_disable_seq;


  function new(string name="test_functional", uvm_component parent);
    super.new(name, parent);
  endfunction:new


  virtual function void build_phase(uvm_phase phase);
  // Build the environment and create the functional sequence
    env = environment::type_id::create("env", this);
    apb_color_disable_seq =  color_disable_seq::type_id::create("apb_color_disable_seq");

    `uvm_info(get_type_name(), $sformatf("Start test_functional"), UVM_LOW)
  endfunction:build_phase

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
	 // Start color_disable_seq, then wait for the I2C transfers to finish

    `uvm_info("FUNCTIONAL_BASE", "real execution begins", UVM_NONE);

      begin
     `ifdef DEBUG
        $display("Starting color_disable sequence for the active agent");
      `endif;
     	apb_color_disable_seq.start(env.apb_mst_agnt.apb_seqr);
      `ifdef DEBUG
        $display("Sequence execution completed for the active agent");
      `endif;
      end

     #20000
    phase.drop_objection(this);
    endtask

  virtual function void report_phase(uvm_phase phase);
    uvm_report_server svr;

    svr = uvm_report_server::get_server();

    // Functional coverage results
    $display("APB functional coverage: %0.2f%%", env.apb_mst_agnt.apb_cov.apb_packet_cg.get_coverage());
    $display("I2C functional coverage: %0.2f%%", env.i2c_slv_agnt.i2c_cov.i2c_cov.get_coverage());

    // Count errors and warnings; if any exist, the test has failed
    $display("error count: %0d \nwarning count: %0d",svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR), svr.get_severity_count(UVM_WARNING));
    if((svr.get_severity_count(UVM_FATAL) +
        svr.get_severity_count(UVM_ERROR) +
        svr.get_severity_count(UVM_WARNING)) > 0)
    begin
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
     	`uvm_info(get_type_name(), "----            TEST FAIL          ----", UVM_NONE)
     	`uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end else begin
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
      `uvm_info(get_type_name(), "----           TEST PASS           ----", UVM_NONE)
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end

    // End the simulation
    $finish();
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction:end_of_elaboration_phase

endclass:test_functional

`endif

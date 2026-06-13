`ifndef TEST_BASE_SV
`define TEST_BASE_SV

// Include files required by the test
`include "environment.sv"
`include "apb_seq_lib.sv"


class test_base extends uvm_test;
  `uvm_component_utils(test_base)

  // Test constructor
  function new(string name = "test_base", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  environment env;

  apb_5_packets apb_5_packets_seq;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = environment::type_id::create("env", this);

    // Create input data sequences and randomize their fields declared with the "rand" keyword
    apb_5_packets_seq =  apb_5_packets::type_id::create("apb_5_packets_seq");
    apb_5_packets_seq.randomize();

  endfunction

  virtual task run_phase(uvm_phase phase);

    // Call the parent class run_phase
    super.run_phase(phase);

    // Raise an objection to indicate that an activity has started;
    // the simulator will not end the "run" phase until the objection is dropped
    phase.raise_objection(this);

    `uvm_info("TEST_BASE", "real execution begins", UVM_NONE);

    // Start the verification sequences (can be launched in parallel using fork-join)
      begin
     `ifdef DEBUG
        $display("Starting sequence for the active agent");
      `endif;
     	apb_5_packets_seq.start(env.apb_mst_agnt.apb_seqr);
      `ifdef DEBUG
        $display("Sequence execution completed for the active agent");
      `endif;
      end

    // Wait before dropping the objection to allow DUT processing to complete
     #20000
    // Drop the objection to allow the simulator to end the run phase
    phase.drop_objection(this);
    endtask

  // In the report phase (after the run phase), display coverage values and test verdict
  virtual function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    super.report_phase(phase);

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

endclass


`endif

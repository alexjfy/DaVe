// Test scenarios from the project specification.
// Each scenario lives in its own class, all of them derive from test_base below.

`ifndef __test_all_scenarios
`define __test_all_scenarios

`include "uvm_macros.svh"
`include "verification_env.sv"
`include "apb_sequence.sv"

// Shared base for every scenario: builds the env, holds the interface
// handles and exposes a couple of helpers (reset, bus cleanup, full
// operand-write-then-START conversion).
class test_base extends uvm_test;
  `uvm_component_utils(test_base)

  verification_env verif_env;
  virtual apb_interface_dut vif_apb_dut;
  virtual spi_interface_dut vif_spi_dut;

  function new(string name = "test_base", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    this.print();
    uvm_top.print_topology();
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    verif_env = verification_env::type_id::create("verif_env", this);
    if (!uvm_config_db#(virtual apb_interface_dut)::get(this, "", "apb_interface_dut", vif_apb_dut))
      `uvm_fatal("TEST", "Could not retrieve the apb_interface_dut interface")
    if (!uvm_config_db#(virtual spi_interface_dut)::get(this, "", "spi_interface_dut", vif_spi_dut))
      `uvm_fatal("TEST", "Could not retrieve the spi_interface_dut interface")
    uvm_config_db#(virtual spi_interface_dut)::set(this, "verif_env.spi_agent_inst.*", "spi_interface_dut", vif_spi_dut);
    uvm_config_db#(virtual apb_interface_dut)::set(this, "verif_env.apb_agent_inst.*", "apb_interface_dut", vif_apb_dut);
  endfunction

  // Drive rst_n low for ~15 clocks and bring it back high.
  virtual task apply_reset();
    vif_apb_dut.rst_n    <= 1;
    vif_apb_dut.paddr    <= 0;
    vif_apb_dut.penable  <= 0;
    vif_apb_dut.psel     <= 0;
    repeat(15) @(posedge vif_apb_dut.pclk);
    vif_apb_dut.rst_n <= 0;
    $display("[TEST] INFO: Reset ACTIVE at T=%0t", $time);
    repeat(15) @(posedge vif_apb_dut.pclk);
    vif_apb_dut.rst_n <= 1;
    $display("[TEST] INFO: Reset DEACTIVATED at T=%0t", $time);
  endtask

  // Park the bus in a safe state after the test body is done.
  virtual task cleanup_bus();
    @(posedge vif_apb_dut.pclk);
    vif_apb_dut.psel     <= 0;
    vif_apb_dut.penable  <= 0;
    vif_apb_dut.paddr    <= 0;
  endtask

  // Full end-to-end conversion helper.
  // Writes `operand` to OPERAND, raises START on CONTROL, and waits for the
  // SPI side to deassert CS before returning. expected_gray is handed back
  // so the caller can double-check against the scoreboard log.
  virtual task automatic do_conversion(
    input bit [7:0] operand,
    output bit [7:0] expected_gray
  );
    apb_seq_write_addr0_fixed_data seq_wr_op;
    apb_seq_write_addr4 seq_wr_ctrl;

    expected_gray = operand ^ (operand >> 1);
    $display("[TEST] INFO: Conversion: operand=0x%0h -> expected_gray=0x%0h at T=%0t",
             operand, expected_gray, $time);

    // 1. write the operand
    seq_wr_op = apb_seq_write_addr0_fixed_data::type_id::create("seq_wr_op");
    seq_wr_op.randomize() with {data_transmitted == operand; num_transactions == 1;};
    seq_wr_op.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // 2. kick off the SPI transmission (START=1 on CONTROL)
    seq_wr_ctrl = apb_seq_write_addr4::type_id::create("seq_wr_ctrl");
    seq_wr_ctrl.randomize() with {num_transactions == 1;};
    seq_wr_ctrl.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // 3. wait for the SPI side to release CS, then let the scoreboard catch up
    @(posedge vif_spi_dut.cs);
    repeat(5) @(posedge vif_apb_dut.pclk);
  endtask

  // PASS/FAIL summary + coverage numbers
  virtual function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    super.report_phase(phase);
    $display("STDOUT: The coverage values obtained for apb are: %3.2f%% ",
             verif_env.apb_agent_inst.monitor_apb_inst0.apb_coverage_inst.stari_apb_cg.get_inst_coverage());
    $display("STDOUT: The coverage values obtained for spi are: %3.2f%% ",
             verif_env.spi_agent_inst.monitor_spi_inst0.spi_coverage_inst.stari_spi_cg.get_inst_coverage());
    svr = uvm_report_server::get_server();
    $display("error count: %0d \nwarning count: %0d",
             svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR),
             svr.get_severity_count(UVM_WARNING));
    if ((svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR)) > 0)
    begin
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
      `uvm_info(get_type_name(), "----            TEST FAIL          ----", UVM_NONE)
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end
    else
    begin
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
      `uvm_info(get_type_name(), "----           TEST PASS           ----", UVM_NONE)
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end
    $finish();
  endfunction
endclass


// Scenario 1 - boundary value conversions.
// Walks through the hand-picked corner values: 0x00, 0xFF, 0x01, 0x80, 0x55,
// 0xAA, 0x7F, 0xFE. Mostly a sanity check that the gray formula holds at the
// edges of the 8-bit range.
class test_boundary_values extends test_base;
  `uvm_component_utils(test_boundary_values)

  function new(string name = "test_boundary_values", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit [7:0] expected_gray;
    // chosen for coverage: min, max, single-bit, alternating patterns
    bit [7:0] test_values[$] = '{8'h00, 8'hFF, 8'h01, 8'h80, 8'h55, 8'hAA, 8'h7F, 8'hFE};

    super.run_phase(phase);
    phase.raise_objection(this);

    apply_reset();
    `uvm_info("test_boundary_values",
      $sformatf("=== SCENARIO 1: Boundary value conversion (%0d values) ===", test_values.size()), UVM_NONE)

    foreach (test_values[i]) begin
      $display("\n[TEST] -------- Boundary value #%0d: 0x%0h --------", i+1, test_values[i]);
      do_conversion(test_values[i], expected_gray);
    end

    cleanup_bus();
    #200;
    phase.drop_objection(this);
  endtask
endclass


// Scenario 2 - register readback.
// Writes a known operand then reads back OPERAND, RESULT and CONTROL to make
// sure the DUT returns the values we expect.
class test_register_readback extends test_base;
  `uvm_component_utils(test_register_readback)

  function new(string name = "test_register_readback", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_seq_write_addr0_fixed_data seq_wr_op;
    apb_seq_read seq_rd;

    super.run_phase(phase);
    phase.raise_objection(this);

    apply_reset();
    `uvm_info("test_register_readback",
      "=== SCENARIO 2: Register readback ===", UVM_NONE)

    // 1. write a known operand (0x2C = 44)
    $display("\n[TEST] Step 1: Write OPERAND = 0x2C");
    seq_wr_op = apb_seq_write_addr0_fixed_data::type_id::create("seq_wr_op");
    seq_wr_op.randomize() with {data_transmitted == 8'h2C; num_transactions == 1;};
    seq_wr_op.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // 2. read OPERAND (addr 0) - should come back as 0x2C
    $display("\n[TEST] Step 2: Read OPERAND (addr 0) - expected 0x2C");
    seq_rd = apb_seq_read::type_id::create("seq_rd");
    seq_rd.randomize() with {read_addr == 0; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // 3. read RESULT (addr 2) - 0x2C ^ (0x2C >> 1) = 0x3A
    $display("\n[TEST] Step 3: Read RESULT (addr 2) - expected 0x3A");
    seq_rd = apb_seq_read::type_id::create("seq_rd_result");
    seq_rd.randomize() with {read_addr == 2; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // 4. read CONTROL (addr 4) - 0x00 fresh after reset
    $display("\n[TEST] Step 4: Read CONTROL (addr 4) - expected 0x00");
    seq_rd = apb_seq_read::type_id::create("seq_rd_ctrl");
    seq_rd.randomize() with {read_addr == 4; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    cleanup_bus();
    #200;
    phase.drop_objection(this);
  endtask
endclass


// Scenario 3 - write to RESULT (read-only).
// The DUT is supposed to answer with PSLVERR and leave RESULT untouched.
class test_write_readonly extends test_base;
  `uvm_component_utils(test_write_readonly)

  function new(string name = "test_write_readonly", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_seq_write_addr0_fixed_data seq_wr_op;
    apb_seq_read seq_rd;
    apb_transaction req_wr_result;

    super.run_phase(phase);
    phase.raise_objection(this);

    apply_reset();
    `uvm_info("test_write_readonly",
      "=== SCENARIO 3: Write to RESULT (read-only) ===", UVM_NONE)

    // 1. write an operand (0x55) - RESULT becomes 0x55 ^ 0x2A = 0x7F
    $display("\n[TEST] Step 1: Write OPERAND = 0x55, RESULT will be 0x7F");
    seq_wr_op = apb_seq_write_addr0_fixed_data::type_id::create("seq_wr_op");
    seq_wr_op.randomize() with {data_transmitted == 8'h55; num_transactions == 1;};
    seq_wr_op.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // 2. try to overwrite RESULT - should trigger PSLVERR
    $display("\n[TEST] Step 2: Attempt write to RESULT (addr 2) with data=0xBB");
    begin
      apb_transaction wr_req;
      apb_seq_generic seq_gen;
      seq_gen = apb_seq_generic::type_id::create("seq_gen");
      seq_gen.randomize() with {
        target_addr == 2;
        target_write == 1;
        target_data == 8'hBB;
        num_transactions == 1;
      };
      seq_gen.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
    end

    // 3. read RESULT - should still be 0x7F
    $display("\n[TEST] Step 3: Read RESULT (addr 2) - should STILL be 0x7F");
    seq_rd = apb_seq_read::type_id::create("seq_rd_result");
    seq_rd.randomize() with {read_addr == 2; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    cleanup_bus();
    #200;
    phase.drop_objection(this);
  endtask
endclass


// Scenario 4 - writes to invalid addresses (1, 3, 5, 6, 7).
// DUT must answer with PSLVERR on each of them.
class test_invalid_address extends test_base;
  `uvm_component_utils(test_invalid_address)

  function new(string name = "test_invalid_address", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit [2:0] invalid_addrs[$] = '{3'd1, 3'd3, 3'd5, 3'd6, 3'd7};

    super.run_phase(phase);
    phase.raise_objection(this);

    apply_reset();
    `uvm_info("test_invalid_address",
      "=== SCENARIO 4: Write to invalid addresses ===", UVM_NONE)

    foreach (invalid_addrs[i]) begin
      apb_seq_generic seq_gen;
      $display("\n[TEST] Attempt write to invalid address %0d", invalid_addrs[i]);
      seq_gen = apb_seq_generic::type_id::create("seq_gen");
      seq_gen.randomize() with {
        target_addr == invalid_addrs[i];
        target_write == 1;
        target_data == 8'hDE;
        num_transactions == 1;
      };
      seq_gen.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
    end

    cleanup_bus();
    #200;
    phase.drop_objection(this);
  endtask
endclass


// Scenario 5 - 5 conversions back-to-back, no gaps.
// Stresses the START pulse + END bit handshake across consecutive transfers.
class test_multiple_conversions extends test_base;
  `uvm_component_utils(test_multiple_conversions)

  function new(string name = "test_multiple_conversions", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit [7:0] expected_gray;
    bit [7:0] operands[$] = '{8'h10, 8'h20, 8'h30, 8'h40, 8'h50};

    super.run_phase(phase);
    phase.raise_objection(this);

    apply_reset();
    `uvm_info("test_multiple_conversions",
      $sformatf("=== SCENARIO 5: %0d consecutive conversions ===", operands.size()), UVM_NONE)

    foreach (operands[i]) begin
      $display("\n[TEST] -------- Conversion #%0d: operand=0x%0h --------", i+1, operands[i]);
      do_conversion(operands[i], expected_gray);
    end

    cleanup_bus();
    #200;
    phase.drop_objection(this);
  endtask
endclass


// Scenario 6 - END bit after a full transmission.
// After a complete SPI transfer the END bit (CONTROL[1]) must read as 1.
class test_end_bit extends test_base;
  `uvm_component_utils(test_end_bit)

  function new(string name = "test_end_bit", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit [7:0] expected_gray;
    apb_seq_read seq_rd;

    super.run_phase(phase);
    phase.raise_objection(this);

    apply_reset();
    `uvm_info("test_end_bit",
      "=== SCENARIO 6: Verify END bit after transmission ===", UVM_NONE)

    // 1. one full conversion
    $display("\n[TEST] Step 1: Complete conversion with operand=0x42");
    do_conversion(8'h42, expected_gray);

    // 2. read CONTROL - bit 1 (END) must be high
    $display("\n[TEST] Step 2: Read CONTROL - END bit (bit 1) must be set");
    seq_rd = apb_seq_read::type_id::create("seq_rd_ctrl");
    seq_rd.randomize() with {read_addr == 4; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // 3. sanity check RESULT value
    $display("\n[TEST] Step 3: Read RESULT - confirm Gray value");
    seq_rd = apb_seq_read::type_id::create("seq_rd_result");
    seq_rd.randomize() with {read_addr == 2; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    cleanup_bus();
    #200;
    phase.drop_objection(this);
  endtask
endclass


// Scenario 7 - N random conversions (N=10).
// Uses $urandom_range so each run exercises a slightly different pattern.
class test_random_conversions extends test_base;
  `uvm_component_utils(test_random_conversions)

  function new(string name = "test_random_conversions", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit [7:0] expected_gray;
    bit [7:0] rand_operand;
    int num_conversions = 10;

    super.run_phase(phase);
    phase.raise_objection(this);

    apply_reset();
    `uvm_info("test_random_conversions",
      $sformatf("=== SCENARIO 7: %0d random conversions ===", num_conversions), UVM_NONE)

    for (int i = 0; i < num_conversions; i++) begin
      rand_operand = $urandom_range(0, 255);
      $display("\n[TEST] -------- Random conversion #%0d: operand=0x%0h (%0d) --------",
               i+1, rand_operand, rand_operand);
      do_conversion(rand_operand, expected_gray);
    end

    cleanup_bus();
    #200;
    phase.drop_objection(this);
  endtask
endclass


// Scenario 8 - default values right after reset.
// All registers should read back as 0 before we touch anything.
class test_default_values extends test_base;
  `uvm_component_utils(test_default_values)

  function new(string name = "test_default_values", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_seq_read seq_rd;

    super.run_phase(phase);
    phase.raise_objection(this);

    apply_reset();
    `uvm_info("test_default_values",
      "=== SCENARIO 8: Default values after reset ===", UVM_NONE)

    // OPERAND (addr 0)
    $display("\n[TEST] Step 1: Read OPERAND after reset - expected 0x00");
    seq_rd = apb_seq_read::type_id::create("seq_rd_op");
    seq_rd.randomize() with {read_addr == 0; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // RESULT (addr 2)
    $display("\n[TEST] Step 2: Read RESULT after reset - expected 0x00");
    seq_rd = apb_seq_read::type_id::create("seq_rd_res");
    seq_rd.randomize() with {read_addr == 2; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // CONTROL (addr 4)
    $display("\n[TEST] Step 3: Read CONTROL after reset - expected 0x00");
    seq_rd = apb_seq_read::type_id::create("seq_rd_ctrl");
    seq_rd.randomize() with {read_addr == 4; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    cleanup_bus();
    #200;
    phase.drop_objection(this);
  endtask
endclass


// Scenario 9 - full end-to-end flow.
// Write -> START -> wait -> read everything back.
class test_full_flow extends test_base;
  `uvm_component_utils(test_full_flow)

  function new(string name = "test_full_flow", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit [7:0] expected_gray;
    apb_seq_read seq_rd;
    bit [7:0] operand = 8'hA5;

    super.run_phase(phase);
    phase.raise_objection(this);

    apply_reset();
    `uvm_info("test_full_flow",
      "=== SCENARIO 9: Complete end-to-end flow ===", UVM_NONE)

    // 1. the conversion itself
    $display("\n[TEST] Step 1: Conversion operand=0x%0h", operand);
    do_conversion(operand, expected_gray);
    $display("[TEST] INFO: Expected Gray = 0x%0h", expected_gray);

    // 2. read back each register
    $display("\n[TEST] Step 2: Readback OPERAND (addr 0)");
    seq_rd = apb_seq_read::type_id::create("seq_rd_op");
    seq_rd.randomize() with {read_addr == 0; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    $display("\n[TEST] Step 3: Readback RESULT (addr 2)");
    seq_rd = apb_seq_read::type_id::create("seq_rd_res");
    seq_rd.randomize() with {read_addr == 2; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    $display("\n[TEST] Step 4: Readback CONTROL (addr 4) - END must be set");
    seq_rd = apb_seq_read::type_id::create("seq_rd_ctrl");
    seq_rd.randomize() with {read_addr == 4; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    cleanup_bus();
    #200;
    phase.drop_objection(this);
  endtask
endclass


// Scenario 10 - operand overwrite.
// First conversion with one operand, then another with a different operand;
// RESULT has to follow on every write to OPERAND.
class test_operand_overwrite extends test_base;
  `uvm_component_utils(test_operand_overwrite)

  function new(string name = "test_operand_overwrite", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit [7:0] expected_gray;
    apb_seq_read seq_rd;

    super.run_phase(phase);
    phase.raise_objection(this);

    apply_reset();
    `uvm_info("test_operand_overwrite",
      "=== SCENARIO 10: Operand overwrite ===", UVM_NONE)

    // first conversion
    $display("\n[TEST] Step 1: First conversion with operand=0x11");
    do_conversion(8'h11, expected_gray);

    // read RESULT after first conversion
    $display("\n[TEST] Step 2: Readback RESULT after first conversion");
    seq_rd = apb_seq_read::type_id::create("seq_rd_res1");
    seq_rd.randomize() with {read_addr == 2; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // second conversion - RESULT must change
    $display("\n[TEST] Step 3: Second conversion with operand=0xEE");
    do_conversion(8'hEE, expected_gray);

    // read RESULT again
    $display("\n[TEST] Step 4: Readback RESULT after second conversion");
    seq_rd = apb_seq_read::type_id::create("seq_rd_res2");
    seq_rd.randomize() with {read_addr == 2; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    cleanup_bus();
    #200;
    phase.drop_objection(this);
  endtask
endclass


// Big coverage-chasing test. Systematically exercises every bin we defined
// on the APB and SPI covergroups, in 4 phases:
//   phase 1: SPI conversions targeting the SPI data bins
//   phase 2: register reads (cross addr x write=0)
//   phase 3: invalid addresses + write to RESULT (PSLVERR path + err bin)
//   phase 4: APB data bins + delay bins
class test_coverage_100 extends test_base;
  `uvm_component_utils(test_coverage_100)

  function new(string name = "test_coverage_100", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    bit [7:0] expected_gray;
    apb_seq_read seq_rd;
    apb_seq_generic seq_gen;

    super.run_phase(phase);
    phase.raise_objection(this);

    apply_reset();
    `uvm_info("test_coverage_100",
      "=== COVERAGE 100% TEST: Systematic exercise of all bins ===", UVM_NONE)

    // phase 1: hit every SPI data bin
    //   bins: min_data(0), random_data(1-154), random_data_1(155-254), max_data(255)
    //   picks: operand=0x00 -> 0x00, 0x02 -> 0x03, 0xC8 -> 0xAC, 0xAA -> 0xFF
    $display("\n[TEST-COV] ===== PHASE 1: SPI conversions for SPI coverage =====");

    $display("\n[TEST-COV] SPI bin min_data: operand=0x00 -> gray=0x00");
    do_conversion(8'h00, expected_gray);

    // gray(0x02) = 0x03, lands in [1,154]
    $display("\n[TEST-COV] SPI bin random_data: operand=0x02 -> gray=0x03");
    do_conversion(8'h02, expected_gray);

    // gray(0xC8) = 0xAC (= 172), lands in [155,254]
    $display("\n[TEST-COV] SPI bin random_data_1: operand=0xC8 -> gray=0xAC");
    do_conversion(8'hC8, expected_gray);

    // gray(0xAA) = 0xAA ^ 0x55 = 0xFF
    $display("\n[TEST-COV] SPI bin max_data: operand=0xAA -> gray=0xFF");
    do_conversion(8'hAA, expected_gray);

    // phase 2: hit the cross addr x write=0 coverage
    $display("\n[TEST-COV] ===== PHASE 2: Register reads (cross addr x read) =====");

    // read OPERAND
    seq_rd = apb_seq_read::type_id::create("seq_rd_op");
    seq_rd.randomize() with {read_addr == 0; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // read RESULT
    seq_rd = apb_seq_read::type_id::create("seq_rd_res");
    seq_rd.randomize() with {read_addr == 2; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // read CONTROL
    seq_rd = apb_seq_read::type_id::create("seq_rd_ctrl");
    seq_rd.randomize() with {read_addr == 4; num_transactions == 1;};
    seq_rd.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // phase 3: invalid addresses + write to RESULT -> PSLVERR + err=1 bin
    $display("\n[TEST-COV] ===== PHASE 3: Invalid addresses (PSLVERR + invalid coverage) =====");

    // write to invalid addr 1
    seq_gen = apb_seq_generic::type_id::create("seq_inv_wr");
    seq_gen.randomize() with {target_addr == 1; target_write == 1; target_data == 8'hDE; num_transactions == 1;};
    seq_gen.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // read from invalid addr 3
    seq_gen = apb_seq_generic::type_id::create("seq_inv_rd");
    seq_gen.randomize() with {target_addr == 3; target_write == 0; target_data == 8'h00; num_transactions == 1;};
    seq_gen.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // write to RESULT (addr 2) - also PSLVERR
    seq_gen = apb_seq_generic::type_id::create("seq_wr_result");
    seq_gen.randomize() with {target_addr == 2; target_write == 1; target_data == 8'hBB; num_transactions == 1;};
    seq_gen.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // phase 4a: hit every APB data bin
    //   bins: zero(0), low_range(1-84), mid_range(85-169), hi_range(170-254), maximum(255)
    $display("\n[TEST-COV] ===== PHASE 4: APB data bins =====");

    // data=0
    begin
      apb_seq_write_addr0_fixed_data seq_d;
      seq_d = apb_seq_write_addr0_fixed_data::type_id::create("seq_d0");
      seq_d.randomize() with {data_transmitted == 8'h00; num_transactions == 1;};
      seq_d.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
    end

    // data=0x32 (50) - low_range
    begin
      apb_seq_write_addr0_fixed_data seq_d;
      seq_d = apb_seq_write_addr0_fixed_data::type_id::create("seq_d50");
      seq_d.randomize() with {data_transmitted == 8'h32; num_transactions == 1;};
      seq_d.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
    end

    // data=0x64 (100) - mid_range, likely covered already but we make sure
    begin
      apb_seq_write_addr0_fixed_data seq_d;
      seq_d = apb_seq_write_addr0_fixed_data::type_id::create("seq_d100");
      seq_d.randomize() with {data_transmitted == 8'h64; num_transactions == 1;};
      seq_d.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
    end

    // data=0xC8 (200) - hi_range
    begin
      apb_seq_write_addr0_fixed_data seq_d;
      seq_d = apb_seq_write_addr0_fixed_data::type_id::create("seq_d200");
      seq_d.randomize() with {data_transmitted == 8'hC8; num_transactions == 1;};
      seq_d.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
    end

    // data=0xFF - maximum
    begin
      apb_seq_write_addr0_fixed_data seq_d;
      seq_d = apb_seq_write_addr0_fixed_data::type_id::create("seq_d255");
      seq_d.randomize() with {data_transmitted == 8'hFF; num_transactions == 1;};
      seq_d.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
    end

    // phase 4b: hit every APB delay bin.
    // The monitor counts idle clks, which adds ~1-2 overhead cycles on top of
    // target_delay, so the numbers below are chosen so that the observed
    // delay lands inside each bin.
    //   bins: minimal_delay(0-3), small_delay(4-8), large_delay(9-15), other_delays(16+)
    $display("\n[TEST-COV] ===== APB delay bins =====");

    // delay=0 -> monitor sees ~1-2 (minimal_delay)
    seq_gen = apb_seq_generic::type_id::create("seq_delay0");
    seq_gen.randomize() with {target_addr == 0; target_write == 1; target_data == 8'h10;
                              target_delay == 0; num_transactions == 1;};
    seq_gen.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // delay=3 -> monitor sees ~4-5 (small_delay)
    seq_gen = apb_seq_generic::type_id::create("seq_delay3");
    seq_gen.randomize() with {target_addr == 0; target_write == 1; target_data == 8'h22;
                              target_delay == 3; num_transactions == 1;};
    seq_gen.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // delay=8 -> monitor sees ~9-10 (large_delay)
    seq_gen = apb_seq_generic::type_id::create("seq_delay8");
    seq_gen.randomize() with {target_addr == 0; target_write == 1; target_data == 8'h33;
                              target_delay == 8; num_transactions == 1;};
    seq_gen.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    // delay=15 -> monitor sees ~16-17 (other_delays)
    seq_gen = apb_seq_generic::type_id::create("seq_delay15");
    seq_gen.randomize() with {target_addr == 0; target_write == 1; target_data == 8'h44;
                              target_delay == 15; num_transactions == 1;};
    seq_gen.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

    $display("\n[TEST-COV] ===== ALL PHASES COMPLETE =====");

    cleanup_bus();
    #200;
    phase.drop_objection(this);
  endtask
endclass

`endif

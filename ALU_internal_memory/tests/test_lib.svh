// Module name: test_lib
// HDL        : UVM
// Description: Test library. The base class `test_lib` builds the environment;
//              every concrete test extends it and, in its run_phase, creates
//              the required APB and reset sequences and starts them on the
//              matching sequencer. All tests complete by dropping their
//              objection on the run_phase.
class test_lib extends uvm_test;

  `uvm_component_utils(test_lib)
  function new( string name = "test_lib", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  environment env;

  virtual function void build_phase (uvm_phase phase);
    super.build_phase (phase);
    env = environment::type_id::create("env", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction : connect_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction
endclass : test_lib


// Smoke test: runs the reset sequence followed by a short mixed op1/op2 APB
// sequence. Good first sanity check that the environment is wired correctly.
class first_test extends test_lib;

  `uvm_component_utils(first_test)
  function new( string name = "first_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);

    op1_op2 op1_op2   = op1_op2::type_id::create("item_apb");
    reset_sequence reset_sequence   = reset_sequence::type_id::create("item_reset");

    phase.raise_objection(this);

    reset_sequence.start(env.agent_reset.seq_reset);
    op1_op2.start(env.agent_apb.seq_apb);

    `uvm_info(get_type_name(),$sformatf ("To be continued...."), UVM_NONE)
    $display("%s TEST: Completed", get_type_name());
    phase.drop_objection (this);

  endtask
endclass : first_test

// Write every memory location with 1s, then read all of them back through
// the valid address range. Exercises the nominal write/read datapath.
class test_write_all_read_all extends test_lib;

  `uvm_component_utils(test_write_all_read_all)
  function new( string name = "test_write_all_read_all", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);

    write_all_with_1 write_all_with_1   = write_all_with_1::type_id::create("item_apb");
    read_all_address read_all_address   = read_all_address::type_id::create("item_apb");
    reset_sequence reset_sequence   = reset_sequence::type_id::create("item_reset");

    phase.raise_objection(this);

    reset_sequence.start(env.agent_reset.seq_reset);
    write_all_with_1.start(env.agent_apb.seq_apb);
    read_all_address.start(env.agent_apb.seq_apb);

    `uvm_info(get_type_name(),$sformatf ("To be continued...."), UVM_NONE)
    $display("%s TEST: Completed", get_type_name());
    phase.drop_objection (this);

  endtask
endclass : test_write_all_read_all

// Same as test_write_all_read_all plus a read to address 20 (out of range),
// to prove the DUT asserts pslverr for an invalid address.
class test_write_all_read_all_error extends test_lib;

  `uvm_component_utils(test_write_all_read_all_error)
  function new( string name = "test_write_all_read_all_error", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);

    write_all_with_1 write_all_with_1   = write_all_with_1::type_id::create("item_apb");
    read_all_address read_all_address   = read_all_address::type_id::create("item_apb");
    read_addr20 read_addr20             = read_addr20::type_id::create("item_apb");
    reset_sequence reset_sequence       = reset_sequence::type_id::create("item_reset");

    phase.raise_objection(this);

    reset_sequence.start(env.agent_reset.seq_reset);
    write_all_with_1.start(env.agent_apb.seq_apb);
    read_all_address.start(env.agent_apb.seq_apb);
    read_addr20.start(env.agent_apb.seq_apb);

    `uvm_info(get_type_name(),$sformatf ("To be continued...."), UVM_NONE)
    $display("%s TEST: Completed", get_type_name());
    phase.drop_objection (this);

  endtask
endclass : test_write_all_read_all_error

// Drives opcode 0000 (reserved / no-op in the ALU) and checks that the DUT
// reports it as an invalid operation rather than producing a result.
class test_opcode_error_check_with_0000 extends test_lib;

  `uvm_component_utils(test_opcode_error_check_with_0000)
  function new( string name = "test_opcode_error_check_with_0000", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);

    opcode0000_write_read_error opcode0000_write_read_error   = opcode0000_write_read_error::type_id::create("item_apb");
    reset_sequence reset_sequence       = reset_sequence::type_id::create("item_reset");

    phase.raise_objection(this);

    reset_sequence.start(env.agent_reset.seq_reset);
    opcode0000_write_read_error.start(env.agent_apb.seq_apb);

    `uvm_info(get_type_name(),$sformatf ("To be continued...."), UVM_NONE)
    $display("%s TEST: Completed", get_type_name());
    phase.drop_objection (this);

  endtask
endclass : test_opcode_error_check_with_0000

// Walk the full set of valid opcodes (0001..1001): ADD, SHIFT, AND, OR, NAND,
// NOR, COMP, etc. Each opcode gets its own write/read sequence to confirm
// the result and status bits.
class test_opcode_check_full extends test_lib;

  `uvm_component_utils(test_opcode_check_full)
  function new( string name = "test_opcode_check_full", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);

    opcode0001_write_read opcode0001_write_read   = opcode0001_write_read::type_id::create("item_apb");
    opcode0010_write_read opcode0010_write_read   = opcode0010_write_read::type_id::create("item_apb");
    opcode0011_write_read opcode0011_write_read   = opcode0011_write_read::type_id::create("item_apb");
    opcode0100_write_read opcode0100_write_read   = opcode0100_write_read::type_id::create("item_apb");
    opcode0101_write_read opcode0101_write_read   = opcode0101_write_read::type_id::create("item_apb");
    opcode0110_write_read opcode0110_write_read   = opcode0110_write_read::type_id::create("item_apb");
    opcode0111_write_read opcode0111_write_read   = opcode0111_write_read::type_id::create("item_apb");
    opcode1000_write_read opcode1000_write_read   = opcode1000_write_read::type_id::create("item_apb");
    opcode1001_write_read opcode1001_write_read   = opcode1001_write_read::type_id::create("item_apb");
    reset_sequence reset_sequence                 = reset_sequence::type_id::create("item_reset");

    phase.raise_objection(this);

    reset_sequence.start(env.agent_reset.seq_reset);
    opcode0001_write_read.start(env.agent_apb.seq_apb);
    opcode0010_write_read.start(env.agent_apb.seq_apb);
    opcode0011_write_read.start(env.agent_apb.seq_apb);
    opcode0100_write_read.start(env.agent_apb.seq_apb);
    opcode0101_write_read.start(env.agent_apb.seq_apb);
    opcode0110_write_read.start(env.agent_apb.seq_apb);
    opcode0111_write_read.start(env.agent_apb.seq_apb);
    opcode1000_write_read.start(env.agent_apb.seq_apb);
    opcode1001_write_read.start(env.agent_apb.seq_apb);

    `uvm_info(get_type_name(),$sformatf ("To be continued...."), UVM_NONE)
    $display("%s TEST: Completed", get_type_name());
    phase.drop_objection (this);

  endtask
endclass : test_opcode_check_full

// Like test_opcode_check_full, but injects a second reset halfway through
// the opcode walk to verify the DUT recovers cleanly mid-stimulus.
class test_opcode_check_full_half_reset extends test_lib;

  `uvm_component_utils(test_opcode_check_full_half_reset)
  function new( string name = "test_opcode_check_full_half_reset", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);

    opcode0001_write_read opcode0001_write_read   = opcode0001_write_read::type_id::create("item_apb");
    opcode0010_write_read opcode0010_write_read   = opcode0010_write_read::type_id::create("item_apb");
    opcode0011_write_read opcode0011_write_read   = opcode0011_write_read::type_id::create("item_apb");
    opcode0100_write_read opcode0100_write_read   = opcode0100_write_read::type_id::create("item_apb");
    opcode0101_write_read opcode0101_write_read   = opcode0101_write_read::type_id::create("item_apb");
    opcode0110_write_read opcode0110_write_read   = opcode0110_write_read::type_id::create("item_apb");
    opcode0111_write_read opcode0111_write_read   = opcode0111_write_read::type_id::create("item_apb");
    opcode1000_write_read opcode1000_write_read   = opcode1000_write_read::type_id::create("item_apb");
    opcode1001_write_read opcode1001_write_read   = opcode1001_write_read::type_id::create("item_apb");
    reset_sequence reset_sequence                 = reset_sequence::type_id::create("item_reset");

    phase.raise_objection(this);

    reset_sequence.start(env.agent_reset.seq_reset);
    opcode0001_write_read.start(env.agent_apb.seq_apb);
    opcode0010_write_read.start(env.agent_apb.seq_apb);
    opcode0011_write_read.start(env.agent_apb.seq_apb);
    opcode0100_write_read.start(env.agent_apb.seq_apb);
    opcode0101_write_read.start(env.agent_apb.seq_apb);
    reset_sequence.start(env.agent_reset.seq_reset);
    opcode0110_write_read.start(env.agent_apb.seq_apb);
    opcode0111_write_read.start(env.agent_apb.seq_apb);
    opcode1000_write_read.start(env.agent_apb.seq_apb);
    opcode1001_write_read.start(env.agent_apb.seq_apb);

    `uvm_info(get_type_name(),$sformatf ("To be continued...."), UVM_NONE)
    $display("%s TEST: Completed", get_type_name());
    phase.drop_objection (this);

  endtask
endclass : test_opcode_check_full_half_reset

// Constrained-random stimulus. Runs the random_seq five times after a single
// reset to stress the DUT across the full input space.
class test_full_random extends test_lib;

  `uvm_component_utils(test_full_random)
  function new( string name = "test_full_random", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);

    random_seq random_seq               = random_seq::type_id::create("item_apb");
    reset_sequence reset_sequence       = reset_sequence::type_id::create("item_reset");

    phase.raise_objection(this);

    reset_sequence.start(env.agent_reset.seq_reset);
    repeat(5)
    random_seq.start(env.agent_apb.seq_apb);


    `uvm_info(get_type_name(),$sformatf ("To be continued...."), UVM_NONE)
    $display("%s TEST: Completed", get_type_name());
    phase.drop_objection (this);

  endtask
endclass : test_full_random

// Same random stimulus as test_full_random but with an extra reset injected
// between bursts, so the DUT is also exercised across a reset boundary.
class test_full_random_with_reset extends test_lib;

  `uvm_component_utils(test_full_random_with_reset)
  function new( string name = "test_full_random_with_reset", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase (uvm_phase phase);

    random_seq random_seq               = random_seq::type_id::create("item_apb");
    reset_sequence reset_sequence       = reset_sequence::type_id::create("item_reset");

    phase.raise_objection(this);

    reset_sequence.start(env.agent_reset.seq_reset);
    repeat(5)
    random_seq.start(env.agent_apb.seq_apb);
    reset_sequence.start(env.agent_reset.seq_reset);
    random_seq.start(env.agent_apb.seq_apb);


    `uvm_info(get_type_name(),$sformatf ("To be continued...."), UVM_NONE)
    $display("%s TEST: Completed", get_type_name());
    phase.drop_objection (this);

  endtask
endclass : test_full_random_with_reset

`ifndef __test_exemplu2
`define __test_exemplu2

`include "uvm_macros.svh"
//include files that the test needs access to
`include "verification_env.sv"
`include "apb_sequence.sv"

class test_exemplu2 extends uvm_test;
  `uvm_component_utils(test_exemplu2)

  //declare the test constructor
  function new(string name = "test_exemplu2", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  //instantiate the verification environment
  verification_env verif_env;

  //instantiate the sequences
  apb_seq_write_addr4 apb_seq_wr_addr4;
  apb_seq_write_addr0 apb_seq_wr_addr0;
  // declare the read sequence that was missing
  apb_seq_read apb_seq_read_addr4;

  //instantiate the virtual interfaces
  virtual apb_interface_dut vif_apb_dut;
  virtual spi_interface_dut vif_spi_dut;

  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    this.print();
    uvm_top.print_topology();
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    //create the verification environment declared above
    verif_env = verification_env::type_id::create("verif_env", this);

    //Get virtual IF handle from top_level and pass it to everything in env level
    if (!uvm_config_db#(virtual apb_interface_dut)::get(this, "", "apb_interface_dut", vif_apb_dut))
      `uvm_fatal("TEST", "Could not retrieve from the UVM database the apb_interface_dut interface")
    if (!uvm_config_db#(virtual spi_interface_dut)::get(this, "", "spi_interface_dut", vif_spi_dut))
      `uvm_fatal("TEST", "Could not retrieve from the UVM database the spi_interface_dut interface")

    uvm_config_db#(virtual spi_interface_dut)::set(this, "verif_env.spi_agent_inst.*", "spi_interface_dut", vif_spi_dut);
    uvm_config_db#(virtual apb_interface_dut)::set(this, "verif_env.apb_agent_inst.*", "apb_interface_dut", vif_apb_dut);

    // Create the sequences
    apb_seq_wr_addr0 = apb_seq_write_addr0::type_id::create("apb_seq_wr_addr0");
    apb_seq_wr_addr0.randomize();
    apb_seq_wr_addr4 = apb_seq_write_addr4::type_id::create("apb_seq_wr_addr4");
    apb_seq_wr_addr4.randomize();
    apb_seq_read_addr4 = apb_seq_read::type_id::create("apb_seq_read_addr4");
    apb_seq_read_addr4.randomize() with {read_addr == 4;};

  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);

    apply_reset();
    `uvm_info("test_exemplu2", "Real execution begins", UVM_NONE);

    fork
      begin
        // 1. Write the operand
        apb_seq_wr_addr0.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
        // 2. Start SPI transmission (START=1)
        apb_seq_wr_addr4.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
        // 3. Read CTRL multiple times to monitor the state
        apb_seq_read_addr4.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
        #40;
        apb_seq_read_addr4.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
        #40;
        apb_seq_read_addr4.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
        #40;
        apb_seq_read_addr4.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
      end
    join

    @(posedge vif_apb_dut.pclk);
    vif_apb_dut.psel     <= 0;
    vif_apb_dut.penable  <= 0;
    vif_apb_dut.paddr    <= 0;
    #500;
    phase.drop_objection(this);
  endtask

  virtual task apply_reset();
    vif_apb_dut.rst_n    <= 1;
    vif_apb_dut.paddr    <= 0;
    vif_apb_dut.penable  <= 0;
    vif_apb_dut.psel     <= 0;
    repeat(15) @(posedge vif_apb_dut.pclk);
    vif_apb_dut.rst_n <= 0;
    $display("[TEST2] INFO: Reset ACTIVE at T=%0t", $time);
    repeat(15) @(posedge vif_apb_dut.pclk);
    vif_apb_dut.rst_n <= 1;
    $display("[TEST2] INFO: Reset DEACTIVATED at T=%0t", $time);
  endtask

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
`endif

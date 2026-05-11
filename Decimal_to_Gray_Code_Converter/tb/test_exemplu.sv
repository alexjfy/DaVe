`ifndef __test_exemplu
`define __test_exemplu

`include "uvm_macros.svh"
//include files that the test needs access to
`include "verification_env.sv"
`include "apb_sequence.sv"

class test_exemplu extends uvm_test;
  `uvm_component_utils(test_exemplu)


  //declare the test constructor
  function new(string name = "test_exemplu", uvm_component parent=null);
    super.new(name, parent);
  endfunction



  //instantiate the verification environment
  verification_env verif_env;

  //instantiate the sequences used by apb_agent and spi_agent
  apb_sequence apb_seq;
  apb_seq_write_addr4 apb_seq_wr_addr4;
  apb_seq_write_addr0 apb_seq_wr_addr0;


  //instantiate the virtual interfaces of the verification environment; these will later be correlated with the real interfaces defined in the interface files

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
      `uvm_fatal("TEST", "Could not retrieve from the UVM database the virtual interface type apb_interface_dut to create vif_apb_dut")
    if (!uvm_config_db#(virtual spi_interface_dut)::get(this, "", "spi_interface_dut", vif_spi_dut))
      `uvm_fatal("TEST", "Could not retrieve from the UVM database the virtual interface type spi_interface_dut to create vif_spi_dut")

      //the virtual interfaces are used to create the connections with the agents
    uvm_config_db#(virtual spi_interface_dut)::set(this, "verif_env.spi_agent_inst.*", "spi_interface_dut",vif_spi_dut);
    uvm_config_db#(virtual apb_interface_dut)::set(this, "verif_env.apb_agent_inst.*", "apb_interface_dut",vif_apb_dut);

    //Create the input data sequences (in this case we only have one sequence, since we only have one active agent), then give random values to the fields declared with the "rand" keyword inside the "secventa_intrari" class

    // apb_seq = apb_sequence::type_id::create("apb_seq");
    // apb_seq.randomize();
    apb_seq_wr_addr0 = apb_seq_write_addr0::type_id::create("apb_seq_wr_addr0");
    apb_seq_wr_addr0.randomize();
    //apb_seq_wr_addr0.randomize() with {data_transmitted == 0};
    apb_seq_wr_addr4 = apb_seq_write_addr4::type_id::create("apb_seq_wr_addr4");
    apb_seq_wr_addr4.randomize();


  endfunction

  virtual task run_phase(uvm_phase phase);

    //call the run_phase function from the parent class
    super.run_phase(phase);

    //raise an objection to indicate that an activity has started; until the activity finishes, the simulator will know not to interrupt the "run" phase of the test; therefore we must make sure to drop the objection at the end of this function
    phase.raise_objection(this);

    //assert the reset signals on the interfaces
    apply_reset();
    `uvm_info("test_exemplu", "real execution begins", UVM_NONE);

    //in the fork join block, the verification environment sequences can be started in parallel
    fork

      begin
      `ifdef DEBUG
        $display("the sequence apb_seq for the active agent agent_apb will start running");
      `endif;
        apb_seq_wr_addr0.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);
        apb_seq_wr_addr4.start(verif_env.apb_agent_inst.sequencer_agent_apb_inst0);

      `ifdef DEBUG
        $display("the sequence for the active agent agent_apb has finished running");
      `endif;


      end

    join
    //after the sequences that send stimuli to the DUT have finished, all input signals are set to 0
    @(posedge vif_apb_dut.pclk);
    vif_apb_dut.psel     <= 0;
    vif_apb_dut.penable  <= 0;
    vif_apb_dut.paddr    <= 0;
    #500//wait 100 more time units before dropping the objection, which will allow the simulator to end the activity
	//drop the objection
    phase.drop_objection(this);
    endtask

  //the interface traffic is reset
  virtual task apply_reset();
    vif_apb_dut.rst_n    <= 1;
    vif_apb_dut.paddr    <= 0;
    vif_apb_dut.penable  <= 0;
    vif_apb_dut.psel     <= 0;
    `ifdef DEBUG
    $display("reset has been asserted");
    `endif;
    repeat(15) @(posedge vif_apb_dut.pclk);
    vif_apb_dut.rst_n <= 0;
     repeat(15) @(posedge vif_apb_dut.pclk);
    vif_apb_dut.rst_n <= 1;
    `ifdef DEBUG
    $display("%t reset has been deasserted", $time());
    `endif;
  endtask

  //in this phase, which occurs after the run phase where the actual activity in the verification environment takes place, we display the coverage values
  virtual function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    super.report_phase(phase);
    $display("STDOUT: The coverage values obtained for apb are: %3.2f%% ",  		   verif_env.apb_agent_inst.monitor_apb_inst0.apb_coverage_inst.stari_apb_cg.get_inst_coverage());
    $display("STDOUT: The coverage values obtained for spi are: %3.2f%% ",  		   verif_env.spi_agent_inst.monitor_spi_inst0.spi_coverage_inst.stari_spi_cg.get_inst_coverage());

    svr = uvm_report_server::get_server();

    //count how many errors and warnings occurred during the test; if there was at least one, it means the test failed and needs to be fixed
     $display("error count: %0d \nwarning count: %0d",svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR), svr.get_severity_count(UVM_WARNING));
      if(svr.get_severity_count(UVM_FATAL) +
         svr.get_severity_count(UVM_ERROR)>0 +
       svr.get_severity_count(UVM_WARNING) > 0)
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

    //issue the directive to end the test
        $finish();
  	endfunction
endclass
`endif
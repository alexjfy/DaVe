`include "uvm_macros.svh"

// `include "trains_agent.sv"
`include "../verification/environment.sv"
`include "../verification/sequences/trains_sequence.sv"
`include "../verification/sequences/single_train_request_sequence.sv"
`include "../verification/sequences/odd_even_priority_sequence.sv"
`include "../verification/sequences/same_parity_priority_sequence.sv"
`include "../verification/sequences/all_requests_sequence.sv"
`include "../verification/sequences/same_train_repeated_sequence.sv"
`include "../verification/sequences/stress_sequence.sv"

class zoo_test_base extends uvm_test;

  //add test to the UVM database
  `uvm_component_utils(zoo_test_base)
  
  //declare the class constructor;
  function new(string name = "zoo_test_base", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  environment env;
  
  trains_sequence               trains_seq;
  single_train_request_sequence single_train_req_seq;
  odd_even_priority_sequence    odd_even_priority_seq;
  same_parity_priority_sequence same_parity_priority_seq;
  same_train_repeated_sequence  same_train_repeated_seq;
  all_requests_sequence         all_requests_seq;
  stress_sequence               stress_seq;
  virtual trains_interface    vif_trains;
  virtual semaphore_interface vif_semaphore;
  
   function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    this.print();
    uvm_top.print_topology();
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = environment::type_id::create("env", this);
    
    if (!uvm_config_db#(virtual trains_interface)::get(this, "", "trains_interface", vif_trains))
      `uvm_fatal("TEST",  {"Virtual interface must be set for: ",get_full_name(),".vif_trains"})
      
    if (!uvm_config_db#(virtual semaphore_interface)::get(this, "", "semaphore_interface", vif_semaphore))
      `uvm_fatal("TEST",  {"Virtual interface must be set for: ",get_full_name(),".vif_semaphore"})
      
    uvm_config_db#(virtual trains_interface)::set(this, "env.trains_agent_inst.*", "trains_interface",vif_trains);
    uvm_config_db#(virtual semaphore_interface)::set(this, "env.semaphore_agent_inst.*", "semaphore_interface",vif_semaphore);
    
    //create the sequences for the test;
    trains_seq = trains_sequence::type_id::create("trains_seq");
    trains_seq.randomize();
    
    single_train_req_seq = single_train_request_sequence::type_id::create("single_train_req_seq");
    single_train_req_seq.randomize();
    
    odd_even_priority_seq = odd_even_priority_sequence::type_id::create("odd_even_priority_seq");
    odd_even_priority_seq.randomize();

    same_parity_priority_seq = same_parity_priority_sequence::type_id::create("same_parity_priority_seq");
    same_parity_priority_seq.randomize();
    
    all_requests_seq = all_requests_sequence::type_id::create("all_requests_seq");
    all_requests_seq.randomize();
    
    same_train_repeated_seq = same_train_repeated_sequence::type_id::create("same_train_repeated_seq");
    same_train_repeated_seq.randomize();

    stress_seq = stress_sequence::type_id::create("stress_seq");
    stress_seq.randomize();
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    
    `uvm_info("ZOO_TEST_BASE", "real execution begins", UVM_NONE);
    
    `uvm_info("ZOO_TEST_BASE", "Start trains_seq sequence", UVM_DEBUG);
    trains_seq.start(env.trains_agent_inst.trains_agent_sequencer_inst);
    `uvm_info("ZOO_TEST_BASE", "End trains_seq sequence", UVM_DEBUG);

      @(posedge vif_trains.clk)
      #100
      phase.drop_objection(this);
    endtask
  
  virtual function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    super.report_phase(phase);
    `uvm_info("ZOO_TEST_BASE", "Coverage report: ", UVM_LOW);
    `uvm_info("", $sformatf("Trains coverage = %3.2f%%", env.trains_agent_inst.trains_agent_monitor_inst.trains_coverage_inst.trains_requests_cg.get_inst_coverage()), UVM_LOW);
    `uvm_info("", $sformatf("Semaphore coverage = %3.2f%%", env.semaphore_agent_inst.semaphore_agent_monitor_inst.semaphore_coverage_inst.semaphore_states_cg.get_inst_coverage()), UVM_LOW);
    `uvm_info("", $sformatf("Section coverage = %3.2f%%", env.IO_scorboard.railway_state_coverage_inst.fsm_cg.get_inst_coverage()), UVM_LOW);
      
    svr = uvm_report_server::get_server();
 
    `uvm_info("ZOO_TEST_BASE", "Test report: ", UVM_LOW);
    `uvm_info("", $sformatf("Errors = %0d", svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR)), UVM_LOW);
    `uvm_info("", $sformatf("Warnings = %0d", svr.get_severity_count(UVM_WARNING)), UVM_LOW);

    if(svr.get_severity_count(UVM_FATAL) +
      svr.get_severity_count(UVM_ERROR)>0 +
      svr.get_severity_count(UVM_WARNING) > 0) 
		begin
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
      `uvm_info(get_type_name(), "----            TEST FAIL          ----", UVM_NONE)
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end	else begin
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
      `uvm_info(get_type_name(), "----           TEST PASS           ----", UVM_NONE)
      `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end
  endfunction 
endclass : zoo_test_base
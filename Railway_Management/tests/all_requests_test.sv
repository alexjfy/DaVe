class all_requests_test extends zoo_test_base;

  //add test to the UVM database
  `uvm_component_utils(all_requests_test)
  
  //declare the class constructor;
  function new(string name = "all_requests_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("all_requests_test", "Test started", UVM_NONE);
    
    `uvm_info("all_requests_test", "Start trains_agent sequence", UVM_DEBUG);
    all_requests_seq.start(env.trains_agent_inst.trains_agent_sequencer_inst);
    `uvm_info("all_requests_test", "End trains_agent sequence", UVM_DEBUG);

    #100
    `uvm_info("all_requests_test", "Test finished", UVM_NONE);
    phase.drop_objection(this);
  endtask
  
endclass : all_requests_test
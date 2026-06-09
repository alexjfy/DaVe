class single_train_request_test extends zoo_test_base;

  //add test to the UVM database
  `uvm_component_utils(single_train_request_test)
  
  //declare the class constructor;
  function new(string name = "single_train_request_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("single_train_request_test", "Test started", UVM_NONE);
    
    `uvm_info("single_train_request_test", "Start trains_agent sequence", UVM_DEBUG);
    single_train_req_seq.start(env.trains_agent_inst.trains_agent_sequencer_inst);
    `uvm_info("single_train_request_test", "End trains_agent sequence", UVM_DEBUG);

    #100
    `uvm_info("single_train_request_test", "Test finished", UVM_NONE);
    phase.drop_objection(this);
  endtask
  
endclass : single_train_request_test
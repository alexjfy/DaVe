class same_parity_priority_test extends zoo_test_base;

  //add test to the UVM database
  `uvm_component_utils(same_parity_priority_test)
  
  //declare the class constructor;
  function new(string name = "same_parity_priority_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("same_parity_priority_test", "Test started", UVM_NONE);
    
    `uvm_info("same_parity_priority_test", "Start trains_agent sequence", UVM_DEBUG);
    same_parity_priority_seq.start(env.trains_agent_inst.trains_agent_sequencer_inst);
    `uvm_info("same_parity_priority_test", "End trains_agent sequence", UVM_DEBUG);

    #100
    `uvm_info("same_parity_priority_test", "Test finished", UVM_NONE);
    phase.drop_objection(this);
  endtask
  
endclass : same_parity_priority_test
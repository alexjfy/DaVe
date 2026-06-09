class odd_even_priority_test extends zoo_test_base;

  //add test to the UVM database
  `uvm_component_utils(odd_even_priority_test)
  
  //declare the class constructor;
  function new(string name = "odd_even_priority_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("odd_even_priority_test", "Test started", UVM_NONE);
    
    `uvm_info("odd_even_priority_test", "Start trains_agent sequence", UVM_DEBUG);
    odd_even_priority_seq.start(env.trains_agent_inst.trains_agent_sequencer_inst);
    `uvm_info("odd_even_priority_test", "End trains_agent sequence", UVM_DEBUG);

    #100
    `uvm_info("odd_even_priority_test", "Test finished", UVM_NONE);
    phase.drop_objection(this);
  endtask
  
endclass : odd_even_priority_test
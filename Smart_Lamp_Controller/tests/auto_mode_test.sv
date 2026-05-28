class auto_mode_test extends lamp_test_base;

  //add test to the UVM database
  `uvm_component_utils(auto_mode_test)
  
  //declare the class constructor;
  function new(string name = "auto_mode_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("auto_mode_test", "Test started", UVM_NONE);
    
    //start the sequences for the button and sensor agents in parallel
    fork
      begin
        `uvm_info("auto_mode_test", "Start sensor_agent sequence", UVM_DEBUG);
        balanced_data_sequence_inst.start(env.sensor_agent_inst.sensor_agent_sequencer_inst);
        `uvm_info("auto_mode_test", "End sensor_agent sequence", UVM_DEBUG);
      end
      begin
        `uvm_info("auto_mode_test", "Start button_agent sequence", UVM_DEBUG);
        auto_mode_sequence_inst.start(env.button_agent_inst.button_agent_sequencer_inst);
        `uvm_info("auto_mode_test", "End button_agent sequence", UVM_DEBUG); 
      end
    join

    #100
    `uvm_info("auto_mode_test", "Test finished", UVM_NONE);
    phase.drop_objection(this);
  endtask
  
endclass
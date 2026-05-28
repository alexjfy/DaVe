class global_test extends lamp_test_base;

  //add test to the UVM database
  `uvm_component_utils(global_test)
  
  //declare the class constructor;
  function new(string name = "global_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("global_test", "Test started", UVM_NONE);
    
    //start the sequences for the button and sensor agents in parallel
    fork
      begin
        `uvm_info("global_test", "Start sensor_agent sequence", UVM_DEBUG);
        balanced_data_sequence_inst.start(env.sensor_agent_inst.sensor_agent_sequencer_inst);
        sensor_sequence_inst.start(env.sensor_agent_inst.sensor_agent_sequencer_inst);
        sensor_limit_values_sequence_inst.start(env.sensor_agent_inst.sensor_agent_sequencer_inst);
        `uvm_info("global_test", "End sensor_agent sequence", UVM_DEBUG);
      end
      begin
        `uvm_info("global_test", "Start button_agent sequence", UVM_DEBUG); 
        random_sequence_inst.start(env.button_agent_inst.button_agent_sequencer_inst);
        #1000
        manual_mode_sequence_inst.start(env.button_agent_inst.button_agent_sequencer_inst);
        one_long_push_button_sequence_inst.start(env.button_agent_inst.button_agent_sequencer_inst);
        manual_mode_sequence_inst.start(env.button_agent_inst.button_agent_sequencer_inst);
        one_long_push_button_sequence_inst.start(env.button_agent_inst.button_agent_sequencer_inst);
        `uvm_info("global_test", "End button_agent sequence", UVM_DEBUG);
      end
    join
    
    #100
    `uvm_info("global_test", "Test finished", UVM_NONE);
    phase.drop_objection(this);
  endtask
  
endclass
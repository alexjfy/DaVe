class manual_mode_test extends lamp_test_base;

  //add test to the UVM database
  `uvm_component_utils(manual_mode_test)
  
  //declare the class constructor;
  function new(string name = "manual_mode_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("manual_mode_test", "Test started", UVM_NONE);
    
    //start the sequences for the button and sensor agents in parallel
    fork
      begin
        `uvm_info("manual_mode_test", "Start sensor_agent sequence", UVM_DEBUG);
        sensor_sequence_inst.start(env.sensor_agent_inst.sensor_agent_sequencer_inst);
        `uvm_info("manual_mode_test", "End sensor_agent sequence", UVM_DEBUG);
      end
      begin
        `uvm_info("manual_mode_test", "Start button_agent sequence", UVM_DEBUG); 
        manual_mode_sequence_inst.start(env.button_agent_inst.button_agent_sequencer_inst);
        one_long_push_button_sequence_inst.start(env.button_agent_inst.button_agent_sequencer_inst);
        manual_mode_sequence_inst.start(env.button_agent_inst.button_agent_sequencer_inst);
        `uvm_info("manual_mode_test", "End button_agent sequence", UVM_DEBUG); 
      end
    join
    
    `uvm_info("manual_mode_test", "Test finished", UVM_NONE);
    #100
    phase.drop_objection(this);
  endtask
  
endclass : manual_mode_test
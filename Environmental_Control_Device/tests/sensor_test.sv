class sensor_test extends ambient_test_base;

  //add test to the UVM database
  `uvm_component_utils(sensor_test)
  
  //declare the class constructor;
  function new(string name = "sensor_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
   function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("sensor_test", "Test started", UVM_NONE);
    
    //start the sequences for the button and sensor agents in parallel
    fork
      begin
        `uvm_info("sensor_test", "Start button_agent sequence", UVM_DEBUG);
        button_seq.start(env.button_agent_inst.button_agent_sequencer_inst);
        `uvm_info("sensor_test", "End button_agent sequence", UVM_DEBUG);
      end
      begin 
      `uvm_info("sensor_test", "Start sensor_agent sequence", UVM_DEBUG);
        random_sensor_seq.start(env.sensor_agent_inst.sensor_agent_sequencer_inst);
        `uvm_info("sensor_test", "End sensor_agent sequence", UVM_DEBUG);
      end
    join
    
    `uvm_info("sensor_test", "Test finished", UVM_NONE);
    #100
    phase.drop_objection(this);
  endtask

endclass : sensor_test
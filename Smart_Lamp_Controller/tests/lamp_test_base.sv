`include "uvm_macros.svh"

`include "../verification/environment.sv"
`include "../verification/sequences/sensor_sequence.sv"
`include "../verification/sequences/mode_switch_sequence.sv"
`include "../verification/sequences/auto_mode_sequence.sv"
`include "../verification/sequences/random_sequence.sv"
`include "../verification/sequences/manual_mode_sequence.sv"
`include "../verification/sequences/sensor_limit_values_sequence.sv"
`include "../verification/sequences/balanced_data_sequence.sv"
`include "../verification/sequences/one_long_push_button_sequence.sv"

class lamp_test_base extends uvm_test;

  //add test to the UVM database
  `uvm_component_utils(lamp_test_base)
  
  //declare the class constructor;
  function new(string name = "lamp_test_base", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  environment env;
 
  auto_mode_sequence                auto_mode_sequence_inst;
  random_sequence                   random_sequence_inst;
  manual_mode_sequence              manual_mode_sequence_inst;
  sensor_sequence                   sensor_sequence_inst;
  balanced_data_sequence            balanced_data_sequence_inst;
  sensor_limit_values_sequence      sensor_limit_values_sequence_inst;
  mode_switch_sequence              mode_switch_sequence_inst;
  one_long_push_button_sequence     one_long_push_button_sequence_inst;
  
  virtual button_interface button_vif;
  virtual sensor_interface sensor_vif;
  virtual lamp_interface   lamp_vif;
  
  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    this.print();
    uvm_top.print_topology();
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = environment::type_id::create("env", this);
    
    if (!uvm_config_db#(virtual button_interface)::get(this, "", "button_interface", button_vif))
      `uvm_fatal("TEST",  {"Virtual interface must be set for: ",get_full_name(),".button_vif"})
      
    if (!uvm_config_db#(virtual sensor_interface)::get(this, "", "sensor_interface", sensor_vif))
      `uvm_fatal("TEST",  {"Virtual interface must be set for: ",get_full_name(),".sensor_vif"})
        
    if (!uvm_config_db#(virtual lamp_interface)::get(this, "", "lamp_interface", lamp_vif))
      `uvm_fatal("TEST",  {"Virtual interface must be set for: ",get_full_name(),".lamp_vif"})
      
    uvm_config_db#(virtual button_interface)::set(this, "env.button_agent_inst.*", "button_if",button_vif);
    uvm_config_db#(virtual sensor_interface)::set(this, "env.sensor_agent_inst.*", "sensor_if",sensor_vif);
    uvm_config_db#(virtual lamp_interface)::set(this, "env.lamp_agent_inst.*", "lamp_if",lamp_vif);
    
    //create the sequences for the test;
    balanced_data_sequence_inst = balanced_data_sequence::type_id::create("balanced_data_sequence");
    balanced_data_sequence_inst.randomize();
    sensor_limit_values_sequence_inst = sensor_limit_values_sequence::type_id::create("sensor_limit_values_sequence");
    sensor_limit_values_sequence_inst.randomize();
    sensor_sequence_inst = sensor_sequence::type_id::create("sensor_sequence");
    sensor_sequence_inst.randomize();
    auto_mode_sequence_inst = auto_mode_sequence::type_id::create("auto_mode_sequence");
    auto_mode_sequence_inst.randomize();
    manual_mode_sequence_inst = manual_mode_sequence::type_id::create("manual_mode_sequence");
    manual_mode_sequence_inst.randomize();
    random_sequence_inst = random_sequence::type_id::create("random_sequence");
    random_sequence_inst.randomize();
    mode_switch_sequence_inst = mode_switch_sequence::type_id::create("mode_switch_sequence");
    mode_switch_sequence_inst.randomize();
    one_long_push_button_sequence_inst = one_long_push_button_sequence::type_id::create("one_long_push_button_sequence");
    one_long_push_button_sequence_inst.randomize();
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    `uvm_info("LAMP_TEST_BASE", "real execution begins", UVM_NONE);
    
    //start the sequences for the button and sensor agents in parallel
    fork
      begin
        `uvm_info("LAMP_TEST_BASE", "Start sensor_agent sequence", UVM_DEBUG);
        sensor_sequence_inst.start(env.sensor_agent_inst.sensor_agent_sequencer_inst);
        `uvm_info("LAMP_TEST_BASE", "End sensor_agent sequence", UVM_DEBUG);
      end
      begin
        `uvm_info("LAMP_TEST_BASE", "Start button_agent sequence", UVM_DEBUG); 
        mode_switch_sequence_inst.start(env.button_agent_inst.button_agent_sequencer_inst);
        `uvm_info("LAMP_TEST_BASE", "End button_agent sequence", UVM_DEBUG); 
      end
    join
    
    @(posedge sensor_vif.clk)
    #100
    phase.drop_objection(this);
  endtask
  
  virtual function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    super.report_phase(phase);
    `uvm_info("LAMP_TEST_BASE", "Coverage report: ", UVM_LOW);
    `uvm_info("", $sformatf("Sensor coverage = %3.2f%%", env.sensor_agent_inst.sensor_agent_monitor_inst.sensor_coverage_inst.sensor_cg.get_inst_coverage()), UVM_LOW);
    `uvm_info("", $sformatf("Button coverage = %3.2f%%", env.button_agent_inst.button_agent_monitor_inst.button_coverage_inst.button_cg.get_inst_coverage()), UVM_LOW);
    `uvm_info("", $sformatf("Lamp   coverage = %3.2f%%", env.lamp_agent_inst.lamp_agent_monitor_inst.lamp_coverage_inst.lamp_state_cg.get_inst_coverage()), UVM_LOW);
    svr = uvm_report_server::get_server();
 
    `uvm_info("LAMP_TEST_BASE", "Test report: ", UVM_LOW);
    `uvm_info("", $sformatf("Errors = %0d", svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR)), UVM_LOW);
    `uvm_info("", $sformatf("Warnings = %0d", svr.get_severity_count(UVM_WARNING)), UVM_LOW);
    
    if(svr.get_severity_count(UVM_FATAL) +
       svr.get_severity_count(UVM_ERROR) +
       svr.get_severity_count(UVM_WARNING) ) 
		begin
      `uvm_info("", "---------------------------------------", UVM_NONE)
      `uvm_info("", "----            TEST FAIL          ----", UVM_NONE)
      `uvm_info("", "---------------------------------------", UVM_NONE)
    end	else begin
      `uvm_info("", "---------------------------------------", UVM_NONE)
      `uvm_info("", "----           TEST PASS           ----", UVM_NONE)
      `uvm_info("", "---------------------------------------", UVM_NONE)
    end
  endfunction 
   
endclass : lamp_test_base
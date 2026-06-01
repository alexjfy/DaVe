`include "uvm_macros.svh"

`include "../verification/environment.sv"

`include "../verification/sequences/fast_switch_sequence.sv"
`include "../verification/sequences/rare_button_sequence.sv"
`include "../verification/sequences/button_sequence.sv"
`include "../verification/sequences/temperature_sequence.sv"
`include "../verification/sequences/humidity_sequence.sv"
`include "../verification/sequences/random_sensor_sequence.sv"
`include "../verification/sequences/sensor_limit_values_sequence.sv"
`include "../verification/sequences/luminosity_sequence.sv"
`include "../verification/sequences/frequent_button_sequence.sv"

class ambient_test_base extends uvm_test;

  //add test to the UVM database
  `uvm_component_utils(ambient_test_base)
  
  //declare the class constructor;
  function new(string name = "ambient_test_base", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  environment env;
  
  button_sequence              button_seq;
  fast_switch_sequence         fast_switch_seq;
  rare_button_sequence         rare_button_seq;
  temperature_sequence         temperature_seq;
  humidity_sequence            humidity_seq;
  random_sensor_sequence       random_sensor_seq;
  sensor_limit_values_sequence sensor_limit_values_seq;
  luminosity_sequence          luminosity_seq;
  frequent_button_sequence     frequent_button_seq;
  
  virtual actuator_interface vif_actuator;
  virtual button_interface   vif_button;
  virtual sensor_interface   vif_sensor;
  
  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    this.print();
    uvm_top.print_topology();
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = environment::type_id::create("env", this);
    if (!uvm_config_db#(virtual button_interface)::get(this, "", "button_interface", vif_button))
      `uvm_fatal("TEST",  {"Virtual interface must be set for: ",get_full_name(),".vif_button"})
       
    if (!uvm_config_db#(virtual sensor_interface)::get(this, "", "sensor_interface", vif_sensor))
      `uvm_fatal("TEST",  {"Virtual interface must be set for: ",get_full_name(),".vif_sensor"})
      
    if (!uvm_config_db#(virtual actuator_interface)::get(this, "", "actuator_interface", vif_actuator))
      `uvm_fatal("TEST",  {"Virtual interface must be set for: ",get_full_name(),".vif_actuator"})
      
    uvm_config_db#(virtual button_interface)::set(this, "env.button_agent_inst.*", "button_interface",vif_button);
    uvm_config_db#(virtual sensor_interface)::set(this, "env.sensor_agent_inst.*", "sensor_interface",vif_sensor);
    uvm_config_db#(virtual actuator_interface)::set(this, "env.actuator_agent_inst.*", "actuator_interface",vif_actuator);
    
    //create the sequences for the test;
    button_seq =  button_sequence::type_id::create("button_seq");
    button_seq.randomize();
    frequent_button_seq =  frequent_button_sequence::type_id::create("frequent_button_seq");
    frequent_button_seq.randomize();
    fast_switch_seq = fast_switch_sequence::type_id::create("fast_switch_seq");
    fast_switch_seq.randomize();
    rare_button_seq = rare_button_sequence::type_id::create("rare_button_seq");
    rare_button_seq.randomize();
    temperature_seq = temperature_sequence::type_id::create("temperature_seq");
    temperature_seq.randomize();
    humidity_seq =  humidity_sequence ::type_id::create("humidity_seq");
    humidity_seq.randomize();
    random_sensor_seq = random_sensor_sequence::type_id::create("random_sensor_seq");
    random_sensor_seq.randomize();
    sensor_limit_values_seq = sensor_limit_values_sequence::type_id::create("sensor_limit_values_seq");
    sensor_limit_values_seq.randomize();
    luminosity_seq = luminosity_sequence::type_id::create("luminosity_seq");
    luminosity_seq.randomize();
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);

    `uvm_info("AMBIENT_TEST_BASE", "real execution begins", UVM_NONE);
    
    //start the sequences for the button and sensor agents in parallel
    fork
      begin
        `uvm_info("AMBIENT_TEST_BASE", "Start button_agent sequence", UVM_DEBUG);
     	  fast_switch_seq.start(env.button_agent_inst.button_agent_sequencer_inst);
        `uvm_info("AMBIENT_TEST_BASE", "End button_agent sequence", UVM_DEBUG);
      end
      
      begin 
        `uvm_info("AMBIENT_TEST_BASE", "Start sensor_agent sequence", UVM_DEBUG);
        temperature_seq.start(env.sensor_agent_inst.sensor_agent_sequencer_inst);
        `uvm_info("AMBIENT_TEST_BASE", "End sensor_agent sequence", UVM_DEBUG); 
      end
    join
    
    @(posedge vif_sensor.clk_i)
    #100
    phase.drop_objection(this);
  endtask
  
  virtual function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    super.report_phase(phase);
    `uvm_info("AMBIENT_TEST_BASE", "Coverage report: ", UVM_LOW);
    `uvm_info("", $sformatf("Sensor   coverage = %3.2f%%", env.sensor_agent_inst.sensor_agent_monitor_inst.sensor_coverage_inst.sensor_cg.get_inst_coverage()), UVM_LOW);
    `uvm_info("", $sformatf("Button   coverage = %3.2f%%", env.button_agent_inst.button_agent_monitor_inst.button_coverage_inst.button_cg.get_inst_coverage()), UVM_LOW);
    `uvm_info("", $sformatf("Actuator coverage = %3.2f%%", env.actuator_agent_inst.actuator_agent_monitor_inst.actuator_coverage_inst.actuator_cg.get_inst_coverage()), UVM_LOW);
    svr = uvm_report_server::get_server();
 
    `uvm_info("AMBIENT_TEST_BASE", "Test report: ", UVM_LOW);
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

endclass : ambient_test_base
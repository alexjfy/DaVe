`ifndef __scoreboard
`define __scoreboard

//declare prefixes for the ports that will be used to receive data from the input agent
`uvm_analysis_imp_decl(_actuator)
`uvm_analysis_imp_decl(_sensor)
`uvm_analysis_imp_decl(_button)

class scoreboard extends uvm_scoreboard;
  
  //the component is added to the database of this project;
  `uvm_component_utils(scoreboard)
  
  uvm_analysis_imp_actuator #(actuator_transaction, scoreboard) actuator_scb_imp;
  uvm_analysis_imp_sensor   #(sensor_transaction, scoreboard)   sensor_scb_imp;
  uvm_analysis_imp_button   #(button_transaction, scoreboard)   button_scb_imp;
  
  global_coverage      global_coverage_inst;
  sensor_transaction   sensor_trans;
  actuator_transaction implicit_actuator_trans;
  actuator_transaction actuator_predicted_trans;
  actuator_transaction actuator_last_trans;
  actuator_transaction actuator_predicted_fifo [$];
  actuator_transaction actuator_received_fifo [$];
  
  bit enable, enable_d;
  
  //declare the class constructor;
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);
    
    actuator_scb_imp = new("actuator_scb_imp", this);
    sensor_scb_imp   = new("sensor_scb_imp", this);
    button_scb_imp   = new("button_scb_imp", this);

    actuator_last_trans = new();
    
    sensor_trans = new();
    implicit_actuator_trans = new();

    actuator_predicted_fifo.push_back(implicit_actuator_trans);
    
    global_coverage_inst = global_coverage::type_id::create("global_coverage_inst", this);
  endfunction
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork
      check_actuator_transactions();
    join_none
  endtask
  
  function void write_sensor(input sensor_transaction trans); 
    `uvm_info("SCOREBOARD", $sformatf("Sensor transaction received:\n %s", trans.sprint()), UVM_LOW)
    sensor_trans = trans;
    global_coverage_inst.processed_data_cg.sample();
    if(enable_d)
      predict_actuator_trans(trans);
    else `uvm_info("SCOREBOARD", $sformatf("Sensor transaction dropped"), UVM_DEBUG)
  endfunction : write_sensor
  
  function void write_button(input button_transaction trans);  
    int fifo_size = actuator_predicted_fifo.size();
    `uvm_info("SCOREBOARD", $sformatf("Button transaction received:\n %s", trans.sprint()), UVM_LOW)
    enable_d = enable;
    enable = trans.enable;
    global_coverage_inst.processed_data_cg.sample();
    if (!enable) //predict implicit transaction
      if(implicit_actuator_trans.compare(actuator_predicted_fifo[fifo_size - 1]) == 0) begin //if predicted transaction is the same as the last transaction, sensor monitor will not send it
        `uvm_info("SCOREBOARD", $sformatf("Predict implicit transaction"), UVM_DEBUG)
        actuator_predicted_fifo.push_back(implicit_actuator_trans);
      end
  endfunction : write_button
  
  function void write_actuator(input actuator_transaction trans);
    `uvm_info("SCOREBOARD", $sformatf("Actuator transaction received:\n %s", trans.sprint()), UVM_LOW)
    actuator_received_fifo.push_back(trans);
  endfunction : write_actuator
  
  function void predict_actuator_trans(sensor_transaction trans);
    int fifo_size = actuator_predicted_fifo.size();
    actuator_predicted_trans = new();
    actuator_predicted_trans.copy(actuator_predicted_fifo[fifo_size-1]);
	  `uvm_info("SCOREBOARD", $sformatf("Last transaction %0d:\n %s", fifo_size-1, actuator_predicted_trans.sprint()), UVM_DEBUG)
    if (enable) begin
      case(trans.temperature) inside
        [0:22] : begin
          `uvm_info("SCOREBOARD", $sformatf("Predict Heat on, AC off"), UVM_DEBUG)
          actuator_predicted_trans.Heat_i = 1;
          actuator_predicted_trans.AC_i = 0;
        end
        [23:25] : begin
          `uvm_info("SCOREBOARD", $sformatf("Predict Heat off"), UVM_DEBUG)
          actuator_predicted_trans.Heat_i = 0;
        end
        [26:40] : begin
          `uvm_info("SCOREBOARD", $sformatf("Predict Heat off, AC on"), UVM_DEBUG)
          actuator_predicted_trans.Heat_i = 0;
          actuator_predicted_trans.AC_i = 1;
        end
      endcase
      case(trans.humidity) inside
         [0:35] : begin
          `uvm_info("SCOREBOARD", $sformatf("Predict Dehumidifier off"), UVM_DEBUG)
          actuator_predicted_trans.Dehumidifier_i = 0;
        end
        [51:100] : begin
          `uvm_info("SCOREBOARD", $sformatf("Predict Dehumidifier on"), UVM_DEBUG)
          actuator_predicted_trans.Dehumidifier_i = 1;
        end
      endcase
      case(trans.luminous_intensity) inside
       [0:200] : begin
          `uvm_info("SCOREBOARD", $sformatf("Predict Blinds open"), UVM_DEBUG)
          actuator_predicted_trans.Blinds_i = 0;
        end 
        [701:1000] : begin
          `uvm_info("SCOREBOARD", $sformatf("Predict Blinds closed"), UVM_DEBUG)
          actuator_predicted_trans.Blinds_i = 1;
        end
      endcase
    end 
	  `uvm_info("SCOREBOARD", $sformatf("Predicted transaction:\n %s", actuator_predicted_trans.sprint()), UVM_DEBUG)
	  `uvm_info("SCOREBOARD", $sformatf("Last transaction:\n %s", actuator_predicted_fifo[fifo_size - 1].sprint()), UVM_DEBUG)
    if(actuator_predicted_trans.compare(actuator_predicted_fifo[fifo_size - 1]) == 0) begin//if predicted transaction is the same as the last transaction, sensor monitor will not send it
      actuator_predicted_fifo.push_back(actuator_predicted_trans);
    end else
      `uvm_info("SCOREBOARD", $sformatf("Prediction dropped"), UVM_DEBUG)
  endfunction
  
  task check_actuator_transactions();
    actuator_transaction actuator_received_trans, actuator_expected_trans;
    forever begin
      wait (actuator_received_fifo.size() > 0 && actuator_predicted_fifo.size() > 1);
      actuator_received_trans = actuator_received_fifo.pop_front();
      actuator_expected_trans = actuator_predicted_fifo[1];
      if(actuator_received_trans.compare(actuator_expected_trans) == 0)
        `uvm_error("SCOREBOARD", $sformatf("DUT output does not match expected output.\nExpected:\n %s\nReceived:\n %s", actuator_expected_trans.sprint(), actuator_received_trans.sprint()) )
      else
        `uvm_info("SCOREBOARD", $sformatf("DUT output matched"), UVM_LOW)
      actuator_predicted_fifo.pop_front();
    end
  endtask

endclass : scoreboard

`endif
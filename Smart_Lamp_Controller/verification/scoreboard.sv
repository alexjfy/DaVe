`ifndef __scoreboard
`define __scoreboard

//declare prefixes for the ports that will be used to receive data from the input agent
`uvm_analysis_imp_decl(_lamp)
`uvm_analysis_imp_decl(_sensor)
`uvm_analysis_imp_decl(_button)

class scoreboard extends uvm_scoreboard;
  
  //the component is added to the database of this project;
  `uvm_component_utils(scoreboard)
  
  uvm_analysis_imp_lamp   #(lamp_transaction, scoreboard)   lamp_scb_imp;
  uvm_analysis_imp_sensor #(sensor_transaction, scoreboard) sensor_scb_imp;
  uvm_analysis_imp_button #(button_transaction, scoreboard) button_scb_imp;
  
  lamp_state_coverage lamp_state_coverage_inst;
	sensor_transaction  sensor_trans;
  button_transaction  button_trans;
  lamp_transaction    lamp_trans;

  bit [7:0] last_sensor_value;
   
  lamp_modes current_mode, next_mode;
  lamp_state current_lamp_state, next_lamp_state;
  
  button_transaction fifo_button[$];
  lamp_transaction   fifo_lamp[$];
  sensor_transaction fifo_sensor[$];

  //declare the class constructor;
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);
    lamp_scb_imp = new("lamp_scb_imp", this);
    sensor_scb_imp = new("sensor_scb_imp", this);
    button_scb_imp = new("button_scb_imp", this);
    
    //declare initial values
    current_mode = OFF;
    next_mode = OFF;
    current_lamp_state = ON_LEVEL_2;
    next_lamp_state = ON_LEVEL_2;

    last_sensor_value = 0;

    sensor_trans = new();
    button_trans = new();
	  lamp_trans = new();					
    
    lamp_state_coverage_inst = lamp_state_coverage::type_id::create("lamp_state_coverage_inst", this);
  endfunction	 
	
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);lamp_state_coverage_inst.p_scoreboard = this;
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork
      predict_lamp_mode();
      predict_lamp_state_auto();
      check_lamp_state();
    join_none
  endtask
  
  function void write_sensor(input sensor_transaction trans);
    `uvm_info("SCOREBOARD", $sformatf("Sensor transaction received:\n %s", trans.sprint()), UVM_LOW)
    fifo_sensor.push_back(trans);
  endfunction : write_sensor  

  function void write_button(input button_transaction trans);  
    `uvm_info("SCOREBOARD", $sformatf("Button transaction received: %s", trans.sprint()), UVM_LOW)
    fifo_button.push_back(trans);
  endfunction : write_button

  function void write_lamp(input lamp_transaction trans);  
    `uvm_info("SCOREBOARD", $sformatf("Lamp transaction received: %s", trans.sprint()), UVM_LOW)
    fifo_lamp.push_back(trans);
  endfunction : write_lamp

  task predict_lamp_mode();
    forever begin
      wait(fifo_button.size() > 0);
      case(current_mode)
        OFF: begin
          if(fifo_button[0].button == SHORT_PUSH_BUTTON) begin
            next_mode = AUTO;
            `uvm_info("SCOREBOARD", "AUTO mode activated", UVM_DEBUG)
          end else if (fifo_button[0].button == LONG_PUSH_BUTTON) begin
            next_mode = MANUAL;
            next_lamp_state = LIGHT_OFF;
            current_lamp_state = LIGHT_OFF;
            `uvm_info("SCOREBOARD", "MANUAL mode activated", UVM_DEBUG)
            `uvm_info("SCOREBOARD", $sformatf("In MANUAL mode, predict next lamp state: %0s", next_lamp_state.name()), UVM_DEBUG)
          end else begin
            next_mode = OFF;
            next_lamp_state = LIGHT_OFF;
            `uvm_info("SCOREBOARD", $sformatf("Predict next lamp state: %0s", next_lamp_state.name()), UVM_DEBUG)
          end
        end
        AUTO: begin
          if(fifo_button[0].button == SHORT_PUSH_BUTTON) begin
            next_mode = OFF;
            next_lamp_state = LIGHT_OFF;
            `uvm_info("SCOREBOARD", "OFF mode activated", UVM_DEBUG)
            `uvm_info("SCOREBOARD", $sformatf("Predict next lamp state: %0s", next_lamp_state.name()), UVM_DEBUG)
          end else if (fifo_button[0].button == LONG_PUSH_BUTTON) begin
            next_mode = MANUAL;
            next_lamp_state = LIGHT_OFF;
            current_lamp_state = LIGHT_OFF;
            `uvm_info("SCOREBOARD", "MANUAL mode activated", UVM_DEBUG)
            `uvm_info("SCOREBOARD", $sformatf("Predict next lamp state: %0s", next_lamp_state.name()), UVM_DEBUG)
          end else begin
            next_mode = AUTO;
          end
        end
        MANUAL: begin
          if(fifo_button[0].button == SHORT_PUSH_BUTTON) begin
            next_mode = MANUAL;
            predict_lamp_state_manual();
          end else if (fifo_button[0].button == LONG_PUSH_BUTTON) begin
            next_mode = AUTO;
            case(last_sensor_value) inside
              [0:63]   : next_lamp_state = ON_LEVEL_2;
              [64:127] : next_lamp_state = ON_LEVEL_1;
              [128:191]: next_lamp_state = ON_LEVEL_0;
              default  : next_lamp_state = LIGHT_OFF ;
            endcase 
            `uvm_info("SCOREBOARD", "AUTO mode activated", UVM_DEBUG)
            `uvm_info("SCOREBOARD", $sformatf("Predict next lamp state: %0s", next_lamp_state.name()), UVM_DEBUG)
          end else begin
            next_mode = MANUAL;
          end
        end
      endcase
      fifo_button.pop_front();
      `uvm_info("SCOREBOARD", $sformatf("current_mode = %0s, next_mode: %0s", current_mode.name(), next_mode.name()), UVM_DEBUG)
      lamp_state_coverage_inst.lamp_transition_coverage_cg.sample();
      current_mode = next_mode;
    end
  endtask : predict_lamp_mode

  task predict_lamp_state_manual();
    `uvm_info("SCOREBOARD", $sformatf("current_lamp_state = %0s, next lamp state: %0s", current_lamp_state.name(), next_lamp_state.name()), UVM_DEBUG)
    case(current_lamp_state)
      LIGHT_OFF : next_lamp_state = ON_LEVEL_0;
      ON_LEVEL_0: next_lamp_state = ON_LEVEL_1;
      ON_LEVEL_1: next_lamp_state = ON_LEVEL_2;
      ON_LEVEL_2: next_lamp_state = LIGHT_OFF;  
    endcase
    lamp_state_coverage_inst.lamp_transition_coverage_cg.sample();
    `uvm_info("SCOREBOARD", $sformatf("In MANUAL mode, predict next lamp state: %0s", next_lamp_state.name()), UVM_DEBUG)
  endtask : predict_lamp_state_manual

  task predict_lamp_state_auto();
    forever begin
      wait(fifo_sensor.size() > 0 && current_mode == AUTO);
      case(fifo_sensor[0].sensor) inside
        [0:63]   : next_lamp_state = ON_LEVEL_2;
        [64:127] : next_lamp_state = ON_LEVEL_1;
        [128:191]: next_lamp_state = ON_LEVEL_0;
        default  : next_lamp_state = LIGHT_OFF ;
      endcase 
      `uvm_info("SCOREBOARD", $sformatf("In AUTO mode, predict lamp state: %0s", next_lamp_state.name()), UVM_DEBUG)
      last_sensor_value = fifo_sensor[0].sensor;
      fifo_sensor.pop_front();
      lamp_state_coverage_inst.lamp_transition_coverage_cg.sample();
    end
  endtask : predict_lamp_state_auto
  
  task check_lamp_state();
    forever begin
      wait(fifo_lamp.size() > 0);
      if (next_mode != OFF) begin
        if(fifo_lamp[0].light_level_out != next_lamp_state) begin
          `uvm_error("SCOREBOARD", $sformatf("Lamp state is incorrect. Expected: %0s, Actual: %0s", next_lamp_state.name(), fifo_lamp[0].light_level_out.name()))
        end else begin
          `uvm_info("SCOREBOARD", $sformatf("Lamp state is correct. Lamp is at level %0s as expected.", fifo_lamp[0].light_level_out.name()), UVM_LOW)
        end
      end
      fifo_lamp.pop_front();
      // lamp_state_coverage_inst.lamp_transition_coverage_cg.sample();
      `uvm_info("SCOREBOARD", $sformatf("current_lamp_state = %0s, next lamp state: %0s", current_lamp_state.name(), next_lamp_state.name()), UVM_DEBUG)
      current_lamp_state = next_lamp_state;
    end
  endtask : check_lamp_state
  
endclass
`endif
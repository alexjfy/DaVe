`ifndef __scoreboard
`define __scoreboard

//declare prefixes for the ports that will be used to receive data from the input agent
`uvm_analysis_imp_decl(_trains)
`uvm_analysis_imp_decl(_semaphore)

class scoreboard extends uvm_scoreboard;
  
  //the component is added to the database of this project;
  `uvm_component_utils(scoreboard)
  
  uvm_analysis_imp_trains    #(trains_transaction, scoreboard)    trains_scb_imp;
  uvm_analysis_imp_semaphore #(semaphore_transaction, scoreboard) semaphore_scb_imp;
  
  railway_state_coverage railway_state_coverage_inst;
  trains_transaction     trains_trans;
  semaphore_transaction  semaphore_predicted_trans;
  semaphore_transaction  semaphore_received_fifo[$];
  semaphore_transaction  semaphore_predicted_fifo[$];
  
  train_state_t current_state, next_state;
  
  //declare the class constructor;
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);

    trains_scb_imp    = new("trains_scb_imp", this);
    semaphore_scb_imp = new("semaphore_scb_imp", this);

    current_state = NO_TRAIN;
    next_state    = NO_TRAIN;
    
    railway_state_coverage_inst = railway_state_coverage::type_id::create("railway_state_coverage_inst", this);
  endfunction
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    railway_state_coverage_inst.p_scoreboard = this;
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork
      check_semaphore_transactions();
    join_none
  endtask: run_phase

  function void predict_semaphore_trans(trains_transaction trans);    
    semaphore_predicted_trans = new();
    case (current_state)
      NO_TRAIN : begin
        if (trains_trans.t1_i == 1) begin //T1 request received - highest priority
          semaphore_predicted_trans.even_semaphore_state = RED;
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          next_state = TRAIN1;
        end else  if (trains_trans.t3_i == 1) begin //T3 request received - has priority over even-numbered trains and T5
          semaphore_predicted_trans.even_semaphore_state = RED;
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          next_state = TRAIN3;
        end else  if (trains_trans.t5_i == 1) begin //T5 request received - has priority over even-numbered trains
          semaphore_predicted_trans.even_semaphore_state = RED;
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          next_state = TRAIN5;
        end else if (trains_trans.t2_i == 1) begin //T2 request received - has priority over other even-numbered trains
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          semaphore_predicted_trans.odd_semaphore_state = RED;
          next_state = TRAIN2;
        end else if (trains_trans.t4_i == 1) begin //T4 request received - has priority over T6
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          semaphore_predicted_trans.odd_semaphore_state = RED;
          next_state = TRAIN4;
        end else if (trains_trans.t6_i == 1) begin //T6 request received - lowest priority
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          semaphore_predicted_trans.odd_semaphore_state = RED;
          next_state = TRAIN6;
        end else begin
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          next_state = NO_TRAIN;
        end
      end
      TRAIN1 : begin
        //next train must be odd-numbered and not T1
        if (trains_trans.t3_i == 1) begin //T3 request received - highest priority
          semaphore_predicted_trans.even_semaphore_state = RED;
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          next_state = TRAIN3;
        end else if (trains_trans.t5_i == 1) begin //T5 request received
          semaphore_predicted_trans.even_semaphore_state = RED;
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          next_state = TRAIN5;
        end else begin
          `uvm_info("SCOREBOARD", $sformatf("T1 or even-numbered train request received - railway free"), UVM_DEBUG)
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          next_state = NO_TRAIN;
        end
      end
      TRAIN2 : begin
        //next train must be even-numbered and not T2
        if (trains_trans.t4_i == 1) begin //T4 request received - highest priority
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          semaphore_predicted_trans.odd_semaphore_state = RED;
          next_state = TRAIN4;
        end else if (trains_trans.t6_i == 1) begin //T6 request received
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          semaphore_predicted_trans.odd_semaphore_state = RED;
          next_state = TRAIN6;
        end else begin
          `uvm_info("SCOREBOARD", $sformatf("T2 or odd-numbered train request received - railway free"), UVM_DEBUG)
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          next_state = NO_TRAIN;
        end
      end
      TRAIN3 : begin
        //next train must be odd-numbered and not T3
        if (trains_trans.t1_i == 1) begin //T1 request received - highest priority
          semaphore_predicted_trans.even_semaphore_state = RED;
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          next_state = TRAIN1;
        end else if (trains_trans.t5_i == 1) begin //T5 request received
          semaphore_predicted_trans.even_semaphore_state = RED;
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          next_state = TRAIN5;
        end else begin
          `uvm_info("SCOREBOARD", $sformatf("T3 or even-numbered train request received - railway free"), UVM_DEBUG)
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          next_state = NO_TRAIN;
        end
      end
      TRAIN4 : begin
        //next train must be even-numbered and not T4
        if (trains_trans.t2_i == 1) begin //T2 request received - highest priority
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          semaphore_predicted_trans.odd_semaphore_state = RED;
          next_state = TRAIN2;
        end else if (trains_trans.t6_i == 1) begin //T6 request received
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          semaphore_predicted_trans.odd_semaphore_state = RED;
          next_state = TRAIN6;
        end else begin
          `uvm_info("SCOREBOARD", $sformatf("T4 or odd-numbered train request received - railway free"), UVM_DEBUG)
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          next_state = NO_TRAIN;
        end
      end
      TRAIN5 : begin
        //next train must be odd-numbered and not T5
        if (trains_trans.t1_i == 1) begin //T1 request received - highest priority
          semaphore_predicted_trans.even_semaphore_state = RED;
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          next_state = TRAIN1;
        end else if (trains_trans.t3_i == 1) begin //T3 request received
          semaphore_predicted_trans.even_semaphore_state = RED;
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          next_state = TRAIN3;
        end else begin
          `uvm_info("SCOREBOARD", $sformatf("T5 or even-numbered train request received - railway free"), UVM_DEBUG)
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          next_state = NO_TRAIN;
        end
      end
      TRAIN6 : begin
        //next train must be even-numbered and not T6
        if (trains_trans.t2_i == 1) begin //T2 request received - highest priority
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          semaphore_predicted_trans.odd_semaphore_state = RED;
          next_state = TRAIN2;
        end else if (trains_trans.t4_i == 1) begin //T4 request received
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          semaphore_predicted_trans.odd_semaphore_state = RED;
          next_state = TRAIN4;
        end else begin
          `uvm_info("SCOREBOARD", $sformatf("T6 or odd-numbered train request received - railway free"), UVM_DEBUG)
          semaphore_predicted_trans.odd_semaphore_state = GREEN;
          semaphore_predicted_trans.even_semaphore_state = GREEN;
          next_state = NO_TRAIN;
        end
      end
      default:  begin
        `uvm_fatal("SCOREBOARD", "Railway state unknown");
      end
    endcase 
    `uvm_info("SCOREBOARD", $sformatf("Predicted semaphore transaction:\n %s", semaphore_predicted_trans.sprint()), UVM_DEBUG)
    semaphore_predicted_fifo.push_back(semaphore_predicted_trans);
    railway_state_coverage_inst.fsm_cg.sample();
    current_state = next_state;
  endfunction
  
  function void write_trains(input trains_transaction trans);  
    `uvm_info("SCOREBOARD", $sformatf("Trains transaction received:\n %s", trans.sprint()), UVM_LOW)
    trains_trans = trans;
    predict_semaphore_trans(trains_trans);
  endfunction : write_trains
  
  function void write_semaphore(input semaphore_transaction trans);
    `uvm_info("SCOREBOARD", $sformatf("Semaphore transaction received:\n %s", trans.sprint()), UVM_LOW)
    semaphore_received_fifo.push_back(trans);
  endfunction : write_semaphore
      
  task check_semaphore_transactions();
    semaphore_transaction semaphore_received_trans, semaphore_expected_trans;
    forever begin
      wait (semaphore_received_fifo.size() > 0 && semaphore_predicted_fifo.size() > 0)
      semaphore_received_trans = semaphore_received_fifo.pop_front();
      semaphore_expected_trans = semaphore_predicted_fifo.pop_front();
      if (semaphore_expected_trans.compare(semaphore_received_trans) == 0)
        `uvm_error("SCOREBOARD", $sformatf("DUT output does not match expected output.\nExpected:\n %s\nReceived:\n %s", semaphore_expected_trans.sprint(), semaphore_received_trans.sprint()) )
      else
        `uvm_info("SCOREBOARD", $sformatf("DUT output matched"), UVM_LOW)
    end
  endtask
    
endclass : scoreboard

`endif
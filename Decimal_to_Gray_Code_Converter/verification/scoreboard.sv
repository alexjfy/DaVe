`include "uvm_macros.svh"
import uvm_pkg::*;

`ifndef __ambient_scoreboard
`define __ambient_scoreboard

`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_spi)

class scoreboard extends uvm_scoreboard;

  // Internal registers (reference model)
  reg [7:0] reg_operand1;  // address 0
  reg [7:0] reg_result;    // address 2 (computed automatically, read-only)
  reg [7:0] reg_ctrl;      // address 4

  // UVM components
  `uvm_component_utils(scoreboard)

  // Ports for transaction reception
  uvm_analysis_imp_apb #(apb_transaction, scoreboard) apb_data_port;
  uvm_analysis_imp_spi #(spi_transaction, scoreboard) spi_data_port;

  // Transaction structures
  apb_transaction received_apb_tx;
  spi_transaction received_spi_tx;
  spi_transaction predicted_reference_tx;

  logic [7:0] binary_num;
  logic [7:0] gray_code;
  logic [7:0] addr;

  // Statistics counters
  int apb_tx_received_count = 0;
  int spi_tx_received_count = 0;
  int correct_checks     = 0;
  int failed_checks     = 0;

  covergroup registers_cg;
    option.per_instance = 1;
    reg_operand1_cp: coverpoint reg_operand1 {
      bins min_val       = {0};
      bins little_values = {[1:127]};
      bins high_values   = {[128:254]};
      bins max_val       = {255};
    }

    reg_result_cp: coverpoint reg_result {
      bins min_val      = {0};
      bins random_val[4] = {[1:254]};
      bins max_val      = {255};
    }

    // CONTROL register bits: bit 7 is INVALID, bit 1 is END
    invalid_cp: coverpoint reg_ctrl[7];
    end_cp:     coverpoint reg_ctrl[1];
  endgroup

  // Constructor
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);
    apb_data_port = new("apb_data_port", this);
    spi_data_port = new("spi_data_port", this);
    predicted_reference_tx = new();
    received_apb_tx = new();
    received_spi_tx = new();
    registers_cg = new();
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  // Gray code computation function
  function spi_transaction compute_result(apb_transaction predicted_tx);
    predicted_reference_tx = new();
    binary_num = predicted_tx.data;
    gray_code = binary_num ^ (binary_num >> 1);
    predicted_reference_tx.data = gray_code;
    $display("[SCOREBOARD] INFO: Gray computation: binary=%0d(0x%0h) -> gray=%0d(0x%0h)",
             binary_num, binary_num, gray_code, gray_code);
    return predicted_reference_tx;
  endfunction

  // APB transaction reception
  function void write_apb(input apb_transaction new_apb_tx);
    apb_tx_received_count++;
    `uvm_info("SCOREBOARD", $sformatf("Received APB transaction #%0d: addr=0x%0h, write=%0b, data=0x%0h, err=%0b",
              apb_tx_received_count, new_apb_tx.addr, new_apb_tx.write,
              new_apb_tx.data, new_apb_tx.err), UVM_LOW)

    addr = new_apb_tx.addr;
    if (new_apb_tx.write == 1) begin
      case (addr)
        0: begin
          reg_operand1 = new_apb_tx.data;
          // Automatically compute Gray result (same as in DUT)
          reg_result = new_apb_tx.data ^ (new_apb_tx.data >> 1);
          // Update prediction for SPI verification
          predicted_reference_tx = compute_result(new_apb_tx);
          `uvm_info("SCOREBOARD", $sformatf("SPI prediction updated: expecting 0x%0h",
                    predicted_reference_tx.data), UVM_LOW)
        end
        // Writing to RESULT (addr 2) is forbidden - DUT returns PSLVERR
        2: begin
          `uvm_info("SCOREBOARD", "Write to RESULT ignored (read-only register)", UVM_LOW)
          // Do NOT update reg_result - it is read-only, computed automatically on write to addr 0
        end
        4: begin
          reg_ctrl = new_apb_tx.data;
          $display("[SCOREBOARD] INFO: Write CTRL: 0x%0h (START=%b, END=%b, INVALID=%b)",
                   new_apb_tx.data, new_apb_tx.data[0],
                   new_apb_tx.data[1], new_apb_tx.data[7]);
        end
        default: begin
          `uvm_info("SCOREBOARD", $sformatf("WARN: Write to unknown address 0x%0h", addr), UVM_LOW)
        end
      endcase
      registers_cg.sample();
    end else begin
      // Read verification - compare with reference model
      case (addr)
        0: begin
          if (reg_operand1 !== new_apb_tx.data)
            `uvm_error("SCOREBOARD", $sformatf("OPERAND read error: expected=0x%0h, received=0x%0h",
                       reg_operand1, new_apb_tx.data))
          else
            $display("[SCOREBOARD] INFO: OPERAND read correct: 0x%0h", new_apb_tx.data);
        end
        2: begin
          if (reg_result !== new_apb_tx.data)
            `uvm_error("SCOREBOARD", $sformatf("RESULT read error: expected=0x%0h, received=0x%0h",
                       reg_result, new_apb_tx.data))
          else
            $display("[SCOREBOARD] INFO: RESULT read correct: 0x%0h", new_apb_tx.data);
        end
        4: begin
          // CTRL changes dynamically (auto-reset START, set END), so we only log
          $display("[SCOREBOARD] INFO: CTRL read: DUT=0x%0h, model=0x%0h",
                   new_apb_tx.data, reg_ctrl);
        end
        default: begin
          `uvm_info("SCOREBOARD", $sformatf("WARN: Read from unknown address 0x%0h", addr), UVM_LOW)
        end
      endcase
    end

    received_apb_tx = new_apb_tx.copy();
  endfunction

  // SPI transaction reception
  function void write_spi(input spi_transaction new_spi_tx);
    spi_tx_received_count++;
    `uvm_info("SCOREBOARD", $sformatf("Received SPI transaction #%0d: data=0x%0h",
              spi_tx_received_count, new_spi_tx.data), UVM_LOW)

    received_spi_tx = new_spi_tx.copy();
    verify_data_match();
  endfunction

  // SPI data correspondence verification
  function void verify_data_match();
    if (received_spi_tx.data !== predicted_reference_tx.data) begin
      failed_checks++;
      `uvm_error("SCOREBOARD", $sformatf(
        "MISMATCH SPI: received=0x%0h, expected=0x%0h (original_operand=0x%0h)",
        received_spi_tx.data,
        predicted_reference_tx.data,
        reg_operand1))
    end else begin
      correct_checks++;
      `uvm_info("SCOREBOARD", $sformatf(
        "MATCH SPI: Gray correct 0x%0h (from operand 0x%0h). Total correct: %0d",
        received_spi_tx.data, reg_operand1, correct_checks), UVM_LOW)
    end
  endfunction

  // Final report at end of simulation
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    $display("===========================================================");
    $display("[SCOREBOARD] FINAL REPORT:");
    $display("  APB transactions received:  %0d", apb_tx_received_count);
    $display("  SPI transactions received:  %0d", spi_tx_received_count);
    $display("  SPI checks correct:  %0d", correct_checks);
    $display("  SPI checks failed:   %0d", failed_checks);
    $display("===========================================================");
  endfunction

endclass
`endif

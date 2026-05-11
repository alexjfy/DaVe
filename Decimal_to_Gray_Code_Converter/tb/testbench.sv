`include "uvm_macros.svh"
import uvm_pkg::*;

`define CLOCK_PERIOD 10


//`define DEBUG      //parameter used to enable messages that we consider necessary only for debug

//setting the meaning of time units in the simulator
`timescale 1ns/1ns

//including files that the top module needs access to

`include "apb_interface_dut.sv"
`include "spi_interface_dut.sv"
`include "test_exemplu.sv"
//`include "test_exemplu2.sv"
`include "test_all_scenarios.sv"
// If using another simulator (EDA Playground, etc.), uncomment the lines below:
// `include "counter.sv"
// `include "design.sv"


module top();
   logic        clk;
   wire         rst_n;
   wire  [2:0]  paddr;
   wire         psel;
   wire         penable;
   wire [7:0]pwdata;
  wire pwrite;
  wire [7:0] prdata;
  wire pready;
  wire pslverr;
   wire         miso;
   wire         mosi;
   wire         cs;
   wire sclk;
  //interface instances are created (in this project there are 2 agents, so there will be 2 interfaces); the interface signals are connected to the top module signals
  apb_interface_dut intf_apb();
  assign intf_apb.pclk = clk;
  assign rst_n            = intf_apb.rst_n;
  assign psel             = intf_apb.psel;
  assign penable          = intf_apb.penable;
  assign paddr            = intf_apb.paddr;
  assign pwdata           = intf_apb.pwdata;
  assign pwrite           = intf_apb.pwrite;
  assign intf_apb.prdata  = prdata;
  assign intf_apb.pready  = pready;
  assign intf_apb.pslverr = pslverr;

  spi_interface_dut intf_spi();


  assign intf_spi.mosi = mosi;
  assign intf_spi.cs   = cs;
  assign intf_spi.sclk = sclk;


  assign miso = intf_spi.miso;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    //generate the clock
	clk = 1;
	forever begin
    #(`CLOCK_PERIOD/2)
    clk <= ~clk;
  end
	end

   initial
  	begin
      //save the interface instances in the UVM database
      uvm_config_db#(virtual apb_interface_dut)::set(null, "*", "apb_interface_dut", intf_apb);
      uvm_config_db#(virtual spi_interface_dut)::set(null, "*", "spi_interface_dut", intf_spi);
      // EXISTING TESTS:
      //run_test("test_exemplu");
      //run_test("test_exemplu2");

      //TEST SCENARIOS (uncomment the desired one):
      //run_test("test_full_flow");              // Scenario 9: Complete end-to-end flow
      //run_test("test_register_readback");   // Scenario 2: Register readback
      //run_test("test_write_readonly");      // Scenario 3: Write to RESULT (PSLVERR)
      //run_test("test_invalid_address");     // Scenario 4: Invalid addresses (PSLVERR)
      //run_test("test_multiple_conversions");// Scenario 5: Multiple conversions
      //run_test("test_end_bit");             // Scenario 6: Verify END bit
      //run_test("test_random_conversions");  // Scenario 7: N random conversions
      //run_test("test_default_values");      // Scenario 8: Default values after reset
      //run_test("test_operand_overwrite");   // Scenario 10: Operand overwrite
      //run_test("test_boundary_values");     // Scenario 1: Boundary values (requires run > 2000ns)
      run_test("test_coverage_100");          // COVERAGE TEST: Exercises all bins (requires run -all)

  	end

  // the DUT is instantiated, connecting the top module signals to its signals
  converter DUT(
	.clk                  (clk    ),
	.rst_n                (rst_n   ),
	.psel                 (psel    ),
	.penable              (penable ),
  .paddr                 (paddr   ),
  .pwdata               (pwdata),
  .pwrite                (pwrite),
  .prdata               (prdata),
  .pready                (pready),
  .pslverr               (pslverr),
  .mosi                  (mosi ),
  .miso                  (miso  ),
  .cs                   (cs),
  .sclk                 (sclk)
);

endmodule
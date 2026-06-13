
`include "apb_interface.sv"
`include "apb_pkg.sv"

`include "i2c_interface.sv"
`include "i2c_pkg.sv"

`include "test_pkg.sv"

module testbench;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import apb_pkg::*;
  import i2c_pkg::*;

// Localparameteres
localparam TEST_ADDR_WIDTH = 5;
localparam TEST_DATA_WIDTH = 32;

// System interface
wire                        clk       ; // System clock; used on th APB interface
wire                        rst_n     ; // System reset; Active low

// APB interface
wire                        psel      ; // Select; Indicates the start of the first transfer phase
wire                        penable   ; // Enable; Indicates the start of the second transfer phase
wire [TEST_ADDR_WIDTH -1:0] paddr     ; // Address
wire                        pwrite    ; // Write/Read enable
wire [TEST_DATA_WIDTH -1:0] pwdata    ; // Write data
wire                        pready    ; // Ready; Indicates that the Slave has completed the transfer
wire [TEST_DATA_WIDTH -1:0] prdata    ; // Read data
wire                        pslverr   ; // Slave error; Is asserted with pready if the Slave encountered an error during a transfer

// I2C interface
triand                      scl       ; // Serial clock
triand                      sda       ; // Serial data
 
clk_rst_generator #(
  .CLK_PERIOD(10)
) i_clk_rst_generator(
  .clk    (clk                ),
  .rst_n  (rst_n              )
);

sensor_top #(
  .ADDR_WIDTH(TEST_ADDR_WIDTH ),
  .DATA_WIDTH(TEST_DATA_WIDTH )
) DUT (
  .clk      (clk              ),
  .rst_n    (rst_n            ),
  .psel     (psel             ),
  .penable  (penable          ),
  .paddr    (paddr            ),
  .pwrite   (pwrite           ),
  .pwdata   (pwdata           ),
  .pready   (pready           ),
  .prdata   (prdata           ),
  .pslverr  (pslverr          ),
  .scl      (scl              ),
  .sda      (sda              )
);

apb_interface #(TEST_ADDR_WIDTH,TEST_DATA_WIDTH) apb_vif (
  .clk  (clk                  ), 
  .rst_n(rst_n                )
);
// outputs
assign paddr   = apb_vif.paddr  ;
assign psel    = apb_vif.psel   ;
assign penable = apb_vif.penable;
assign pwrite  = apb_vif.pwrite ;
assign pwdata  = apb_vif.pwdata ;
// inputs
assign apb_vif.prdata  = prdata ;
assign apb_vif.pready  = pready ;
assign apb_vif.pslverr = pslverr;

i2c_interface i2c_vif (
  .clk  (clk                  ), 
  .rst_n(rst_n                )
);
// input
assign i2c_vif.scl = scl;
// bidirectional SDA
assign sda = i2c_vif.sda_drive;  // slave drives the triand wire
assign i2c_vif.sda = sda;        // monitor reads the triand wire

initial begin

  uvm_config_db #(virtual interface apb_interface#(TEST_ADDR_WIDTH,TEST_DATA_WIDTH))::set(null,"*", "apb_vif", apb_vif);
  
  uvm_config_db #(virtual interface i2c_interface)::set(null, "*.env.i2c_slv_agnt.*", "i2c_vif", i2c_vif);

  run_test("test_functional");


end

endmodule
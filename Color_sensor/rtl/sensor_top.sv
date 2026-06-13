module sensor_top #(
parameter ADDR_WIDTH = 5,
parameter DATA_WIDTH = 32
)(
  // System interface
  input clk                               , // System clock; used on the APB interface
  input rst_n                             , // System reset; Active low

  // APB interface
  input                           psel    , // Select; Indicates the start of the first transfer phase
  input                           penable , // Enable; Indicates the start of the second transfer phase  
  input       [ADDR_WIDTH -1:0]   paddr   , // Address
  input                           pwrite  , // Write/Read enable
  input       [DATA_WIDTH -1:0]   pwdata  , // Write data
  output                          pready  , // Ready; Indicates that the Slave has completed the transfer
  output reg  [DATA_WIDTH -1:0]   prdata  , // Read data
  output                          pslverr , // Slave error; Is asserted together with pready if the Slave encountered an error during a transfer

  // I2C interface
  inout                           scl     , // Serial clock
  inout                           sda       // Serial data
);

// ----------------
// Local parameters
// ----------------
localparam ADDR_CONFIG      = 5'h00;
localparam ADDR_CLEAR_CH    = 5'h02;
localparam ADDR_RED_CH      = 5'h04;
localparam ADDR_GREEN_CH    = 5'h06;
localparam ADDR_BLUE_CH     = 5'h08;
localparam ADDR_INFRARED_CH = 5'h0C;
localparam ADDR_SEED        = 5'h10;
localparam ADDR_STATUS      = 5'h12;

// Registers
wire [15:0] reg_config;       // Configuration register - R/W
                              // bit[15:14] - 00 = 100 kHz
                              //            - 01 = 400 kHz
                              //            - 10 = 1 MHz
                              //            - 11 = 3.4 MHz
                              // bit[13:7]  - I2C target address
                              // bit[6]     - Endianness
                              // bit[5]     - Infrared_channel_on
                              // bit[4]     - Blue_channel_on
                              // bit[3]     - Green_channel_on
                              // bit[2]     - Red_channel_on
                              // bit[1]     - Clear_channel_on
                              // bit[0]     - SD (Shutdown)

wire [15:0] reg_clear_ch;     // Clear (ambient light) channel - RO
wire [15:0] reg_red_ch;       // Red color channel - RO
wire [15:0] reg_green_ch;     // Green color channel - RO
wire [15:0] reg_blue_ch;      // Blue color channel - RO
wire [15:0] reg_infrared_ch;  // Infrared light channel - RO
wire [15:0] reg_seed;         // LFSR seed - R/W
wire [15:0] reg_status;       // Status register - RO

wire [15:0] clear_data;
wire [15:0] red_data;
wire [15:0] green_data;
wire [15:0] blue_data;
wire [15:0] infrared_data;

// Wires
wire        p_valid_wr;
wire        reg_freeze;
wire        i2c_clk;
wire [15:0] lfsr_seed;
wire        nack;
wire        bsy;
wire        clk_out;
wire        sensor_on;
wire        data_enable;
wire        i2c_clk_out;
wire        sda_en;
wire        endian;

assign pready     = psel & penable;
assign pslverr    = pready && ((paddr > 5'h12) || (paddr[0]) || (paddr == 5'h0A) || (paddr == 5'h0E));
assign p_valid_wr = psel & penable & pwrite & pready & ~reg_freeze;
assign lfsr_seed  = reg_seed;
assign sensor_on  = ~reg_config[0];
assign endian     = reg_config[6];

always @(*) begin
  case (paddr)
    ADDR_CONFIG:      prdata <= {{(DATA_WIDTH-5'd16){1'b0}}, reg_config};
    ADDR_CLEAR_CH:    prdata <= (reg_config[1]) ? {{(DATA_WIDTH-5'd16){1'b0}}, reg_clear_ch} : {DATA_WIDTH{1'b0}};
    ADDR_RED_CH:      prdata <= (reg_config[2]) ? {{(DATA_WIDTH-5'd16){1'b0}}, reg_red_ch} : {DATA_WIDTH{1'b0}}; 
    ADDR_GREEN_CH:    prdata <= (reg_config[3]) ? {{(DATA_WIDTH-5'd16){1'b0}}, reg_green_ch} : {DATA_WIDTH{1'b0}};
    ADDR_BLUE_CH:     prdata <= (reg_config[4]) ? {{(DATA_WIDTH-5'd16){1'b0}}, reg_blue_ch} : {DATA_WIDTH{1'b0}};
    ADDR_INFRARED_CH: prdata <= (reg_config[5]) ? {{(DATA_WIDTH-5'd16){1'b0}}, reg_infrared_ch} : {DATA_WIDTH{1'b0}};
    ADDR_SEED:        prdata <= {{(DATA_WIDTH-5'd16){1'b0}}, reg_seed};
    ADDR_STATUS:      prdata <= {{(DATA_WIDTH-5'd16){1'b0}}, reg_status};
    default:          prdata <= {DATA_WIDTH{1'b0}};
  endcase
end

// ----------------
// APB registers
// ----------------
registers #(
  .REG_WIDTH(16),
  .DATA_WIDTH(DATA_WIDTH),
  .ADDR_WIDTH(ADDR_WIDTH)
) i_registers(
  .clk              (clk              ),
  .rst_n            (rst_n            ),
  .pwdata           (pwdata           ),
  .paddr            (paddr            ),
  .p_valid_wr       (p_valid_wr       ),
  .clear_data       (clear_data       ),
  .red_data         (red_data         ),
  .green_data       (green_data       ),
  .blue_data        (blue_data        ),
  .infrared_data    (infrared_data    ),
  .nack             (nack             ),
  .bsy              (bsy              ),
  .reg_config       (reg_config       ),
  .reg_clear_ch     (reg_clear_ch     ),
  .reg_red_ch       (reg_red_ch       ),
  .reg_green_ch     (reg_green_ch     ),
  .reg_blue_ch      (reg_blue_ch      ),
  .reg_infrared_ch  (reg_infrared_ch  ),
  .reg_seed         (reg_seed         ),
  .reg_status       (reg_status       )
);

// ----------------
// 500MHz clock generator
// ----------------
clk_generator i2c_clock(
  .rst_n      (rst_n    ),
  .clk_out    (clk_out  )
);

// ----------------
// I2C clock generator
// ----------------
clk_divider  i_clk_divider(
  .clk_in       (clk_out            ),
  .rst_n        (rst_n              ),
  .clk_config   (reg_config[15:14]  ),
  .i2c_clk_out  (i2c_clk_out),
  .sda_en       (sda_en)
);

// ----------------
// I2C master control
// ----------------
control master_control(
  .clk            (clk                ),
  .rst_n          (rst_n              ),
  .clk_in         (clk_out            ),
  .i2c_clk_out    (i2c_clk_out        ),
  .i2c_scl        (scl                ),
  .i2c_sda        (sda                ),
  .sensor_on      (sensor_on          ),
  .i2c_address    (reg_config[13:7]   ),
  .sda_en         (sda_en             ),
  .clear_data     (clear_data         ),
  .red_data       (red_data           ),
  .green_data     (green_data         ),
  .blue_data      (blue_data          ),
  .infrared_data  (infrared_data      ),
  .endian         (endian             ),
  .data_enable    (data_enable        ),
  .reg_freeze     (reg_freeze         ),
  .bsy            (bsy                ),
  .nack           (nack               )
);

// ----------------
// Clear random data generator
// ----------------
lfsr #(
  .CHOICE(5)
) clear_random(
  .clk          (clk                          ),
  .rst_n        (rst_n                        ),
  .enable       (reg_config[1] & data_enable  ),
  .seed_data    (lfsr_seed                    ),
  .r_LFSR       (clear_data                   )
);

// ----------------
// Red random data generator
// ----------------
lfsr #(
  .CHOICE(3)
) red_random(
  .clk          (clk                          ),
  .rst_n        (rst_n                        ),
  .enable       (reg_config[2] & data_enable  ),
  .seed_data    (lfsr_seed                    ),
  .r_LFSR       (red_data                     )
);

// ----------------
// Green random data generator
// ----------------
lfsr #(
  .CHOICE(7)
) green_random(
  .clk          (clk                          ),
  .rst_n        (rst_n                        ),
  .enable       (reg_config[3] & data_enable  ),
  .seed_data    (lfsr_seed                    ),
  .r_LFSR       (green_data                   )
);

// ----------------
// Blue random data generator
// ----------------
lfsr #(
  .CHOICE(6)
) blue_random(
  .clk          (clk                          ),
  .rst_n        (rst_n                        ),
  .enable       (reg_config[4] & data_enable  ),
  .seed_data    (lfsr_seed                    ),
  .r_LFSR       (blue_data                    )
);

// ----------------
// Infrared random data generator
// ----------------
lfsr #(
  .CHOICE(4)
) infrared_random(
  .clk          (clk                          ),
  .rst_n        (rst_n                        ),
  .enable       (reg_config[5] & data_enable  ),
  .seed_data    (lfsr_seed                    ),
  .r_LFSR       (infrared_data                )
);

endmodule : sensor_top
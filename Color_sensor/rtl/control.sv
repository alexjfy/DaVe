module control(
  input         clk             , // System clock
  input         rst_n           , // Active-low asynchronous reset
  input         clk_in          , // 500MHz clock
  input         i2c_clk_out     , // Clock for I2C output timing
  output        i2c_scl         , // I2C clock line
  inout         i2c_sda         , // I2C bidirectional data line
  input         sensor_on       , // Sensor enable signal
  input [ 6:0]  i2c_address     , // 7-bit I2C address 
  input         sda_en          , // SDA output enable control
  input [15:0]  clear_data      , // Clear (ambient light) channel data
  input [15:0]  red_data        , // Red color channel data
  input [15:0]  green_data      , // Green color channel data
  input [15:0]  blue_data       , // Blue color channel data
  input [15:0]  infrared_data   , // Infrared channel data
  input         endian          , // Endianness control
  output reg    data_enable     , // Indicates when LFSR data can be update
  output reg    reg_freeze      , // Freezes internal registers (to prevent updates)
  output reg    bsy             , // I2C bus busy flag
  output reg    nack              // Indicates I2C NACK was received
);

localparam STATE_SIZE             = 5;
localparam ST_IDLE                = 0;
localparam ST_WAIT_1              = 1;
localparam ST_START_SDA           = 2;
localparam ST_START_SCL           = 3;
localparam ST_STOP_SDA            = 4;
localparam ST_STOP_SCL            = 5;
localparam ST_ADDRESS             = 6;
localparam ST_CHECK_RSP_ADDR      = 7;
localparam ST_CLEAR_DATA_1        = 8;
localparam ST_CLEAR_DATA_2        = 9;
localparam ST_CLEAR_DATA_RSP_1    = 10;
localparam ST_CLEAR_DATA_RSP_2    = 11;
localparam ST_RED_DATA_1          = 12;
localparam ST_RED_DATA_2          = 13;
localparam ST_RED_DATA_RSP_1      = 14;
localparam ST_RED_DATA_RSP_2      = 15;
localparam ST_GREEN_DATA_1        = 16;
localparam ST_GREEN_DATA_2        = 17;
localparam ST_GREEN_DATA_RSP_1    = 18;
localparam ST_GREEN_DATA_RSP_2    = 19;
localparam ST_BLUE_DATA_1         = 20;
localparam ST_BLUE_DATA_2         = 21;
localparam ST_BLUE_DATA_RSP_1     = 22;
localparam ST_BLUE_DATA_RSP_2     = 23;
localparam ST_INFRARED_DATA_1     = 24;
localparam ST_INFRARED_DATA_2     = 25;
localparam ST_INFRARED_DATA_RSP_1 = 26;
localparam ST_INFRARED_DATA_RSP_2 = 27;

localparam DIVIDER_VALUE = 50;

reg [STATE_SIZE -1:0] c_state;
reg [STATE_SIZE -1:0] next_state;
reg [12:0]            counter;
reg [12:0]            divider_value;
reg                   i2c_scl_enable;
reg                   i2c_sda_enable;
reg                   sda_out;
reg [7:0]             address_shift;
reg [3:0]             bit_count;
reg [7:0]             reg_clear_data_1;
reg [7:0]             reg_clear_data_2;
reg [7:0]             reg_red_data_1;
reg [7:0]             reg_red_data_2;
reg [7:0]             reg_green_data_1;
reg [7:0]             reg_green_data_2;
reg [7:0]             reg_blue_data_1;
reg [7:0]             reg_blue_data_2;
reg [7:0]             reg_infrared_data_1;
reg [7:0]             reg_infrared_data_2;
wire                  reset_counter;

assign i2c_scl = (i2c_scl_enable) ? i2c_clk_out : 1'b1;
assign i2c_sda = (i2c_sda_enable) ? sda_out : 1'b1;
assign reset_counter = (counter == DIVIDER_VALUE - 1);

always @(posedge clk_in or negedge rst_n) begin
  if(~rst_n)  c_state <= ST_IDLE;     else
              c_state <= next_state;
end

always @(posedge clk_in or negedge rst_n) begin
  if(~rst_n)         counter <= 13'b0;           else
  if(reset_counter)  counter <= 13'b0;           else
                     counter <= counter + 1'b1;
end

always @(*) begin
  case(c_state)
    ST_IDLE: begin
      i2c_scl_enable  <= 1'b0;
      i2c_sda_enable  <= 1'b0;
      sda_out         <= 1'b1;
      data_enable     <= 1'b0;
      bsy             <= 1'b0;
      reg_freeze      <= 1'b0;
      bit_count       <= 4'b0;
      nack            <= 1'b0;
      if(sensor_on) begin
        counter     <= 13'b0;
        data_enable <= 1'b1;
        reg_freeze  <= 1'b1;
        next_state  <= ST_WAIT_1;
      end else begin
        next_state  <= ST_IDLE;
      end
    end
    ST_WAIT_1: begin
      data_enable <= 1'b0;
      if(reset_counter)
        next_state <= ST_START_SDA;
      else
        next_state <= ST_WAIT_1;
    end
    ST_START_SDA: begin
      if(reset_counter) begin
        i2c_sda_enable  <= 1'b1;
        sda_out         <= 1'b0;
        bsy             <= 1'b1;
        next_state      <= ST_START_SCL;
      end else
        next_state <= ST_START_SDA;
    end
    ST_START_SCL: begin
      if(reset_counter) begin
        i2c_scl_enable  <= 1'b1;
        next_state      <= ST_ADDRESS;
      end else
        next_state <= ST_START_SCL;
    end
    ST_STOP_SDA: begin
      i2c_sda_enable  <= 1'b0;
      reg_freeze      <= 1'b0;
      bsy             <= 1'b0;
      next_state      <= ST_IDLE;
    end
    ST_STOP_SCL: begin
      i2c_scl_enable <= 1'b0;
      if(reset_counter) begin
        next_state <= ST_STOP_SDA;
      end else 
        next_state <= ST_STOP_SCL;
    end
    ST_ADDRESS: begin
      if(~(|bit_count)) begin
        address_shift <= {i2c_address, 1'b0};
        bit_count     <= 4'd10;
      end
      if(bit_count == 4'd1) begin
        sda_out     <= 1'b1;
        next_state  <= ST_CHECK_RSP_ADDR;
      end else
        next_state <= ST_ADDRESS;
    end

    ST_CLEAR_DATA_1: begin
      if(~(|bit_count)) begin
        reg_clear_data_1  <= (endian) ? clear_data[15:8] : clear_data[7:0];
        bit_count         <= 4'd10;
      end
      if(bit_count == 4'd1) begin
        sda_out     <= 1'b1;
        next_state  <= ST_CLEAR_DATA_RSP_1;
      end else
        next_state <= ST_CLEAR_DATA_1;
    end
    ST_CLEAR_DATA_2: begin
      if(~(|bit_count)) begin
        reg_clear_data_2  <= (endian) ? clear_data[7:0] : clear_data[15:8];
        bit_count         <= 4'd10;
      end
      if(bit_count == 4'd1) begin
        sda_out     <= 1'b1;
        next_state  <= ST_CLEAR_DATA_RSP_2;
      end else
        next_state <= ST_CLEAR_DATA_2;
    end

    ST_RED_DATA_1: begin
      if(~(|bit_count)) begin
        reg_red_data_1  <= (endian) ? red_data[15:8] : red_data[7:0];
        bit_count       <= 4'd10;
      end
      if(bit_count == 4'd1) begin
        sda_out     <= 1'b1;
        next_state  <= ST_RED_DATA_RSP_1;
      end else
        next_state <= ST_RED_DATA_1;
    end
    ST_RED_DATA_2: begin
      if(~(|bit_count)) begin
        reg_red_data_2  <= (endian) ? red_data[7:0] : red_data[15:8];
        bit_count       <= 4'd10;
      end
      if(bit_count == 4'd1) begin
        sda_out <= 1'b1;
        next_state <= ST_RED_DATA_RSP_2;
      end else
        next_state <= ST_RED_DATA_2;
    end

    ST_GREEN_DATA_1: begin
      if(~(|bit_count)) begin
        reg_green_data_1 <= (endian) ? green_data[15:8] : green_data[7:0];
        bit_count <= 4'd10;
      end
      if(bit_count == 4'd1) begin
        sda_out <= 1'b1;
        next_state <= ST_GREEN_DATA_RSP_1;
      end else
        next_state <= ST_GREEN_DATA_1;
    end
    ST_GREEN_DATA_2: begin
      if(~(|bit_count)) begin
        reg_green_data_2 <= (endian) ? green_data[7:0] : green_data[15:8];
        bit_count <= 4'd10;
      end
      if(bit_count == 4'd1) begin
        sda_out <= 1'b1;
        next_state <= ST_GREEN_DATA_RSP_2;
      end else
        next_state <= ST_GREEN_DATA_2;
    end

    ST_BLUE_DATA_1: begin
      if(~(|bit_count)) begin
        reg_blue_data_1 <= (endian) ? blue_data[15:8] : blue_data[7:0];
        bit_count <= 4'd10;
      end
      if(bit_count == 4'd1) begin
        sda_out <= 1'b1;
        next_state <= ST_BLUE_DATA_RSP_1;
      end else
        next_state <= ST_BLUE_DATA_1;
    end
    ST_BLUE_DATA_2: begin
      if(~(|bit_count)) begin
        reg_blue_data_2 <= (endian) ? blue_data[7:0] : blue_data[15:8];
        bit_count <= 4'd10;
      end
      if(bit_count == 4'd1) begin
        sda_out <= 1'b1;
        next_state <= ST_BLUE_DATA_RSP_2;
      end else
        next_state <= ST_BLUE_DATA_2;
    end

    ST_INFRARED_DATA_1: begin
      if(~(|bit_count)) begin
        reg_infrared_data_1 <= (endian) ? infrared_data[15:8] : infrared_data[7:0];
        bit_count <= 4'd10;
      end
      if(bit_count == 4'd1) begin
        sda_out <= 1'b1;
        next_state <= ST_INFRARED_DATA_RSP_1;
      end else
        next_state <= ST_INFRARED_DATA_1;
    end
    ST_INFRARED_DATA_2: begin
      if(~(|bit_count)) begin
        reg_infrared_data_2 <= (endian) ? infrared_data[7:0] : infrared_data[15:8];
        bit_count <= 4'd10;
      end
      if(bit_count == 4'd1) begin
        sda_out <= 1'b1;
        next_state <= ST_INFRARED_DATA_RSP_2;
      end else
        next_state <= ST_INFRARED_DATA_2;
    end
  endcase
end

always @(posedge sda_en) begin
  case(c_state)
    ST_ADDRESS: begin
      sda_out <= address_shift[7];
      address_shift <= {address_shift[6:0], 1'b0};
      bit_count <= bit_count - 1;
    end

    ST_CLEAR_DATA_1: begin
      sda_out <= reg_clear_data_1[7];
      reg_clear_data_1 <= {reg_clear_data_1[6:0], 1'b0};
      bit_count <= bit_count - 1;
    end
    ST_CLEAR_DATA_2: begin
      sda_out <= reg_clear_data_2[7];
      reg_clear_data_2 <= {reg_clear_data_2[6:0], 1'b0};
      bit_count <= bit_count - 1;
    end

    ST_RED_DATA_1: begin
      sda_out <= reg_red_data_1[7];
      reg_red_data_1 <= {reg_red_data_1[6:0], 1'b0};
      bit_count <= bit_count - 1;
    end
    ST_RED_DATA_2: begin
      sda_out <= reg_red_data_2[7];
      reg_red_data_2 <= {reg_red_data_2[6:0], 1'b0};
      bit_count <= bit_count - 1;
    end

    ST_GREEN_DATA_1: begin
      sda_out <= reg_green_data_1[7];
      reg_green_data_1 <= {reg_green_data_1[6:0], 1'b0};
      bit_count <= bit_count - 1;
    end
    ST_GREEN_DATA_2: begin
      sda_out <= reg_green_data_2[7];
      reg_green_data_2 <= {reg_green_data_2[6:0], 1'b0};
      bit_count <= bit_count - 1;
    end

    ST_BLUE_DATA_1: begin
      sda_out <= reg_blue_data_1[7];
      reg_blue_data_1 <= {reg_blue_data_1[6:0], 1'b0};
      bit_count <= bit_count - 1;
    end
    ST_BLUE_DATA_2: begin
      sda_out <= reg_blue_data_2[7];
      reg_blue_data_2 <= {reg_blue_data_2[6:0], 1'b0};
      bit_count <= bit_count - 1;
    end

    ST_INFRARED_DATA_1: begin
      sda_out <= reg_infrared_data_1[7];
      reg_infrared_data_1 <= {reg_infrared_data_1[6:0], 1'b0};
      bit_count <= bit_count - 1;
    end
    ST_INFRARED_DATA_2: begin
      sda_out <= reg_infrared_data_2[7];
      reg_infrared_data_2 <= {reg_infrared_data_2[6:0], 1'b0};
      bit_count <= bit_count - 1;
    end
  endcase
end

always @(posedge i2c_clk_out) begin
  case(c_state)
    ST_CHECK_RSP_ADDR: begin
      bit_count <= 'b0;
      if(i2c_sda) begin
        counter <= 13'd0;
        nack <= 1'b1;
        next_state <= ST_STOP_SCL;
      end else
        next_state <= ST_CLEAR_DATA_1;
    end
    ST_CLEAR_DATA_RSP_1: begin
      bit_count <= 'b0;
      if(i2c_sda) begin
        counter <= 13'd0;
        nack <= 1'b1;
        next_state <= ST_STOP_SCL;
      end else
        next_state <= ST_CLEAR_DATA_2;
    end
    ST_CLEAR_DATA_RSP_2: begin
      bit_count <= 'b0;
      if(i2c_sda) begin
        counter <= 13'd0;
        nack <= 1'b1;
        next_state <= ST_STOP_SCL;
      end else
        next_state <= ST_RED_DATA_1;
    end
    ST_RED_DATA_RSP_1: begin
      bit_count <= 'b0;
      if(i2c_sda) begin
        counter <= 13'd0;
        nack <= 1'b1;
        next_state <= ST_STOP_SCL;
      end else
        next_state <= ST_RED_DATA_2;
    end
    ST_RED_DATA_RSP_2: begin
      bit_count <= 'b0;
      if(i2c_sda) begin
        counter <= 13'd0;
        nack <= 1'b1;
        next_state <= ST_STOP_SCL;
      end else
        next_state <= ST_GREEN_DATA_1;
    end
    ST_GREEN_DATA_RSP_1: begin
      bit_count <= 'b0;
      if(i2c_sda) begin
        counter <= 13'd0;
        nack <= 1'b1;
        next_state <= ST_STOP_SCL;
      end else
        next_state <= ST_GREEN_DATA_2;
    end
    ST_GREEN_DATA_RSP_2: begin
      bit_count <= 'b0;
      if(i2c_sda) begin
        counter <= 13'd0;
        nack <= 1'b1;
        next_state <= ST_STOP_SCL;
      end else
        next_state <= ST_BLUE_DATA_1;
    end
    ST_BLUE_DATA_RSP_1: begin
      bit_count <= 'b0;
      if(i2c_sda) begin
        counter <= 13'd0;
        nack <= 1'b1;
        next_state <= ST_STOP_SCL;
      end else
        next_state <= ST_BLUE_DATA_2;
    end
    ST_BLUE_DATA_RSP_2: begin
      bit_count <= 'b0;
      if(i2c_sda) begin
        counter <= 13'd0;
        nack <= 1'b1;
        next_state <= ST_STOP_SCL;
      end else
        next_state <= ST_INFRARED_DATA_1;
    end
    ST_INFRARED_DATA_RSP_1: begin
      bit_count <= 'b0;
      if(i2c_sda) begin
        counter <= 13'd0;
        nack <= 1'b1;
        next_state <= ST_STOP_SCL;
      end else
        next_state <= ST_INFRARED_DATA_2;
    end
    ST_INFRARED_DATA_RSP_2: begin
      bit_count <= 'b0;
      counter <= 13'd0;
      if(i2c_sda)
        nack <= 1'b1;
      next_state <= ST_STOP_SCL;
    end
  endcase
end

endmodule
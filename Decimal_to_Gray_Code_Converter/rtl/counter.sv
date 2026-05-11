// Configurable up/down counter with synchronous load.
// Used by the converter to pace the SPI bit transmission (count_out walks
// from NO_OF_SPI_BITS-1 down to 0, one step per sclk falling edge).

`timescale 1ns/1ns

module counter(clk, rst_n, count_up_down, enable, load, data_in, count_out, terminate_cnt);
  input logic clk;
  input logic rst_n;
  input logic load;
  input logic enable;
  input logic count_up_down;  // 0 = count down, 1 = count up
  input logic [7:0] data_in;

  output logic [7:0] count_out;
  output logic terminate_cnt;

  always @(posedge clk or negedge rst_n)
    if (~rst_n)
      count_out <= 0;
    else if (~enable)
      count_out <= count_out;          // hold
    else if (load)
      count_out <= data_in;            // load has priority over the +/- update
    else if (~count_up_down && count_out != 0)
      count_out <= count_out - 1;
    else if (count_up_down && count_out != 0)
      count_out <= count_out + 1;

  // combinational: terminate_cnt goes high when we sit at 0
  always @* begin
    if (count_out == 0)
      terminate_cnt = 1;
    else
      terminate_cnt = 0;
  end

endmodule

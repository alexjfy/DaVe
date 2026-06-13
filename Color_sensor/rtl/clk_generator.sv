module clk_generator (
  input       rst_n   , // Active-low asynchronous reset
  output reg  clk_out   // 500MHz clock
);

always @(negedge rst_n)
  if(~rst_n)  clk_out <= 1'b0;


always @(*) begin
  #1ns  clk_out <= ~clk_out; // 500MHz frequency
end
endmodule
module clk_rst_generator #(
  parameter CLK_PERIOD = 10
)(
  output reg  clk,
  output reg  rst_n
);

initial forever #(CLK_PERIOD/2) clk = ~clk; 

initial begin
  clk   = 1'b1;
  rst_n = 1'b1;
  repeat($urandom_range(10,1)) #3;
  rst_n = 1'b0;
  repeat(2) @(posedge clk);
  rst_n = 1'b1;
end

endmodule
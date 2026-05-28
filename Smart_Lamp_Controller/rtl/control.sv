module control 
#(
  parameter WIDTH    = 'd8,
  parameter off      = 'd0,
  parameter on0      = 'd1,
  parameter on1      = 'd2,
  parameter on2      = 'd3,
  parameter auto     = 'd4,
  parameter disabled = 'd5
)(
  input      clk,
  input      reset,
  input      short_push,
  input      long_push,
  output     done,			  
  output reg s_off,
  output reg s_on0,
  output reg s_on1,
  output reg s_on2,
  output reg s_auto,
  output reg s_disable,
  output reg ready
);
  
  reg [2:0] current_state;
  reg [2:0] next_state;
  
  always @(*) begin
    if(reset == 1)begin
      case (current_state)
        off:
          if(short_push)
            next_state <= on0;
          else if(long_push)
            next_state <= auto;
        on0:
          if(short_push)
            next_state <= on1;
          else if(long_push)
            next_state <= auto;
        on1:
          if(short_push)
            next_state <= on2;
          else if(long_push)
            next_state <= auto;
        on2:
          if(short_push)
            next_state <= off;
          else if(long_push)
            next_state <= auto;
        auto:
          if(short_push)
            next_state <= disabled;
          else if(long_push)
            next_state <= off;
        disabled:
          if(short_push)
            next_state <= auto;
          else if(long_push)
            next_state <= off;
      endcase
    end
  end
  
  assign s_off     = (current_state == off)      ? 'b1 : 'b0;
  assign s_disable = (current_state == disabled) ? 'b1 : 'b0;
  assign s_on0     = (current_state == on0)      ? 'b1 : 'b0;
  assign s_on1     = (current_state == on1)      ? 'b1 : 'b0;
  assign s_on2     = (current_state == on2)      ? 'b1 : 'b0;
  assign s_auto    = (current_state == auto)     ? 'b1 : 'b0;
  
  always @(posedge clk or negedge reset) begin
    if(reset == 0)begin
      ready <= 0;
    end
    else
      ready <= (next_state == auto) ? 'b1 : 'b0;
  end
  
  assign done = (next_state == auto);
  
  always @(posedge clk or negedge reset) begin
    if(reset == 0)begin
      current_state <= disabled;
      next_state <= disabled;
    end
    else
      current_state <= next_state;
  end
endmodule
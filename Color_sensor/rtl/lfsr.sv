module lfsr #(
parameter CHOICE = 0 // Selects between different LFSR polynomial tap configurations
) (
  input               clk       , // System clock
  input               rst_n     , // Active-low asynchronous reset
  input               enable    , // LFSR enable signal; allows shifting only when high
  input       [15:0]  seed_data , // Initial seed value to load into the LFSR
  output reg  [15:0]  r_LFSR      // Current value of the LFSR (pseudo-random output)
);

reg r_XNOR;

// Load seed on reset; otherwise shift left and feed back the tap bit while enabled
always @(posedge clk or negedge rst_n) begin
  if(~rst_n)    r_LFSR <= seed_data;                else
  if(enable)    r_LFSR <= {r_LFSR[14:0], r_XNOR};
end

always @(*) begin
  case(CHOICE)
    0: r_XNOR = r_LFSR[10] ^ r_LFSR[7];
    1: r_XNOR = r_LFSR[9] ^ r_LFSR[5];
    2: r_XNOR = r_LFSR[15] ^ r_LFSR[14];
    3: r_XNOR = r_LFSR[11] ^ r_LFSR[9];
    4: r_XNOR = r_LFSR[8] ^ r_LFSR[6] ^ r_LFSR[5] ^ r_LFSR[4];
    5: r_XNOR = r_LFSR[14] ^ r_LFSR[5] ^ r_LFSR[3] ^ r_LFSR[1];
    6: r_XNOR = r_LFSR[12] ^ r_LFSR[6] ^ r_LFSR[4] ^ r_LFSR[1];
    7: r_XNOR = r_LFSR[13] ^ r_LFSR[4] ^ r_LFSR[3] ^ r_LFSR[1];
    default: r_XNOR = r_LFSR[15] ^ r_LFSR[14] ^ r_LFSR[12] ^ r_LFSR[3];
  endcase
end



endmodule
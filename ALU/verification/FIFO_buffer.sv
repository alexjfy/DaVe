module FIFO_buffer #(
parameter DATA_WIDTH = 9,
parameter DEPTH      = 256
) (
    input                           clk       , // System clock
    input                           clear     , // Clear signal
    input                           we        , // Write enable signal
    input                           re        , // Read enable signal
    input      [DATA_WIDTH -1:0]    data_in   , // Input data
    output reg [DATA_WIDTH -1:0]    data_out  , // Output data
    output                          empty     , // Empty fifo signal
    output                          full        // Full fifo signal
);

reg [$clog2(DEPTH) -1:0] wp; // Write pointer
reg [$clog2(DEPTH) -1:0] rp; // Read pointer
reg [DATA_WIDTH -1:0] memory [DEPTH -1:0]; // FIFO storage

always @(posedge clk) begin
  if(clear) begin
    wp        <= 1'b0;
    rp        <= 1'b0;
    data_out  <= 'b0;
  end
end

// Writes and reads are separate always blocks so we don't block the read
// path when the FIFO is full and the opposite way around
always @(posedge clk) begin
  if(we & !full) begin
    memory[wp] <= data_in;
    wp <= wp + 1;
    $display("T=%0t [FIFO] PUSH data=0x%0h wp=%0d", $time, data_in, wp);
  end
end

always @(posedge clk) begin
  if(re & !empty) begin
    data_out <= memory[rp];
    rp <= rp + 1;
    $display("T=%0t [FIFO] POP  data=0x%0h rp=%0d", $time, memory[rp], rp);
  end
end

// Circular buffer: full when write pointer would catch the read pointer on
// the next cycle; empty when they match. This is why we lose one slot of
// usable DEPTH (full = wp+1 == rp, not wp == rp).
assign full   = ((wp + 1) == rp);
assign empty  = (wp == rp);

endmodule
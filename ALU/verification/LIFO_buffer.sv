module LIFO_buffer #(
parameter DATA_WIDTH = 16,
parameter DEPTH      = 256
) (
    input                           clk         ,   // System clock
    input                           clear       ,   // Clear signal
    input                           we          ,   // Write enable signal
    input                           re          ,   // Read enable signal
    input       [DATA_WIDTH -1:0]   data_in     ,   // Input data
    output reg  [DATA_WIDTH -1:0]   data_out    ,   // Output data
    output                          empty       ,   // Empty lifo signal
    output                          full            // Full lifo signal
);

reg [DATA_WIDTH -1:0] memory [DEPTH -1:0]; // stack storage

reg [DATA_WIDTH -1:0] next_data_out;
reg [$clog2(DEPTH) -1:0] index;    // next free slot (top-of-stack + 1)
reg [$clog2(DEPTH) -1:0] next_index;

// empty when index is 0; full when index hits DEPTH
assign empty = ~(|index);
assign full = ~(|(index ^ DEPTH));

integer i;

always @(posedge clk) begin
  if(clear) begin
    data_out <= 'b0;
    index    <= 'b0;
  end else begin
    data_out <= next_data_out;
    index    <= next_index;
  end
end

// Combinational push/pop. On pop we read memory[index-1] because index points
// to the next free slot, not the top.
always @(*) begin
  if(we) begin
    memory[index] = data_in;
    next_index    = index + 1'b1;
    $display("T=%0t [LIFO] PUSH data=0x%0h (index %0d -> %0d)", $time, data_in, index, index+1'b1);
  end else
  if(re) begin
    next_data_out = memory[index - 1'b1];
    next_index    = index - 1'b1;
    $display("T=%0t [LIFO] POP  data=0x%0h (index %0d -> %0d)", $time, memory[index - 1'b1], index, index-1'b1);
  end else begin
    next_data_out = data_out;
    next_index    = index;
  end
end

endmodule
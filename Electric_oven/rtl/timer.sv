// Module: timer
// Description: Countdown timer. Loads a value on 'start', decrements each clock
//              cycle, and asserts 'timeout' when the counter reaches zero.
module timer (
    input  logic       clk,
    input  logic       reset,
    input  logic       start,
    input  logic [7:0] timer,
    output reg   [7:0] timer_remain,
    output reg         timeout
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            timer_remain <= 8'h0;
            timeout      <= 1'b0;
        end else if (start) begin
            // Load the timer value and clear timeout so a new countdown starts clean.
            timer_remain <= timer;
            timeout      <= 1'b0;
            $display("%0t [TIMER] START: loading value %0d", $time(), timer);
        end else if (timer_remain > 8'h0) begin
            timer_remain <= timer_remain - 1;
            timeout      <= 1'b0;
            if (timer_remain == 8'h1)
                $display("%0t [TIMER] Last tick, timeout will assert next cycle", $time());
        end else begin
            // timer_remain is already 0 — hold it and keep timeout asserted.
            timer_remain <= 8'h0;
            timeout      <= 1'b1;
        end
    end

endmodule

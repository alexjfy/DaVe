// Module: mod_ready
// Description: Combinational logic that asserts the LED (mod_ready) when ALL of
//              the following conditions are satisfied:
//                - An operating mode is active (COOK / HEAT / PIZZA / DEFROST)
//                - Temperature is set above 0 degrees
//                - Timer has expired (timeout = 1)
//                - Door is closed (door = 1)
//              The LED stays high as long as all conditions remain met.
//              timer_remain is accepted only for logging/debug purposes; the
//              functional decision uses the timeout signal produced by the timer.
module mod_ready (
    input wire       COOK, HEAT, PIZZA, DEFROST, timeout,
    input wire [7:0] timer_remain,
    input wire [7:0] temp_out,
    input logic      door,   // 1: door closed; 0: door open
    output logic     mod_ready
);

    // Single combinational block: LED is ON only when every required condition holds.
    always_comb begin : READY_LOGIC
        if ((COOK || HEAT || PIZZA || DEFROST) && (temp_out > 8'h0) && timeout && door) begin
            mod_ready = 1'b1;
            $display("%0t [MOD_READY] LED ON: mode_active=%0b, door=%0b, temp_out=%0d, timeout=%0b, timer_remain=%0d",
                     $time(), (COOK || HEAT || PIZZA || DEFROST), door, temp_out, timeout, timer_remain);
        end else begin
            mod_ready = 1'b0;
        end
    end

endmodule

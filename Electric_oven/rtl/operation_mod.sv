// Module: operation_mod
// Description: FSM for the oven operating modes. Transitions from IDLE to one of
//              the four modes (COOK, HEAT, PIZZA, DEFROST) based on req[2:0].
//              Transitions between modes always go through IDLE (by design).
//              Values greater than 4 in req[2:0] are ignored — the FSM stays in
//              its current state. Outputs are registered (one-cycle delay).
module operation_mod (
    input  logic       clock, reset,
    input  logic [7:0] req,
    output logic       COOK, HEAT, PIZZA, DEFROST
);

    // One-hot state encoding: one bit per state, only one bit is high at a time.
    parameter SIZE     = 5;
    parameter IDLE     = 5'b00001;
    parameter COOK0    = 5'b00010;
    parameter HEAT1    = 5'b00100;
    parameter PIZZA2   = 5'b01000;
    parameter DEFROST3 = 5'b10000;

    // Current and next state registers.
    logic [SIZE-1:0] state, next_state;

    // Only the lower 3 bits of req encode the mode selection.
    wire [2:0] mode_req = req[2:0];

    // FSM combinational next-state logic.
    // Any transition between two active modes must first return to IDLE —
    // this guarantees a clean hand-off and avoids ambiguous cross-state jumps.
    always_comb begin : FSM_COMBO
        case (state)
            IDLE: begin
                case (mode_req)
                    3'b001:  next_state = COOK0;
                    3'b010:  next_state = HEAT1;
                    3'b011:  next_state = PIZZA2;
                    3'b100:  next_state = DEFROST3;
                    default: next_state = IDLE;
                endcase
            end
            COOK0:    next_state = (mode_req == 3'b001) ? COOK0    : IDLE;
            HEAT1:    next_state = (mode_req == 3'b010) ? HEAT1    : IDLE;
            PIZZA2:   next_state = (mode_req == 3'b011) ? PIZZA2   : IDLE;
            DEFROST3: next_state = (mode_req == 3'b100) ? DEFROST3 : IDLE;
            default:  next_state = IDLE;
        endcase
    end

    // FSM sequential logic: state register updates on each clock edge.
    always_ff @(posedge clock or posedge reset) begin : FSM_SEQ
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
            if (state != next_state)
                $display("%0t [FSM] State transition: %05b -> %05b (mode_req=%03b)",
                         $time(), state, next_state, mode_req);
        end
    end

    // Output logic: one-hot-decoded outputs, registered to avoid glitches.
    // Adds one clock-cycle latency between state change and output change.
    always_ff @(posedge clock or posedge reset) begin : OUTPUT_LOGIC
        if (reset) begin
            COOK    <= 1'b0;
            HEAT    <= 1'b0;
            PIZZA   <= 1'b0;
            DEFROST <= 1'b0;
        end else begin
            COOK    <= (state == COOK0);
            HEAT    <= (state == HEAT1);
            PIZZA   <= (state == PIZZA2);
            DEFROST <= (state == DEFROST3);
        end
    end

endmodule

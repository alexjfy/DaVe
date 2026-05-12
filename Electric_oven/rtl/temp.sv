// Module: temp
// Description: Converts a temperature selector value (0-4) into the corresponding
//              temperature in degrees: 0 -> 0, 1 -> 50, 2 -> 100, 3 -> 150, 4 -> 200.
//              Values greater than 4 default to 0 degrees.
module temp(
    input  logic       reset,
    input  logic       clk,
    input  logic [7:0] temp_set,
    output logic [7:0] temp_out
);

    // Registered output so the conversion result is stable for downstream logic.
    reg [7:0] temp_current_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            temp_current_reg <= 8'h0;
        end else begin
            // Only the lower 3 bits are meaningful (values 0-4).
            case (temp_set[2:0])
                3'b000:  temp_current_reg <= 8'h0;    // 0 degrees
                3'b001:  temp_current_reg <= 8'd50;   // 50 degrees
                3'b010:  temp_current_reg <= 8'd100;  // 100 degrees
                3'b011:  temp_current_reg <= 8'd150;  // 150 degrees
                3'b100:  temp_current_reg <= 8'd200;  // 200 degrees
                default: temp_current_reg <= 8'h0;    // Invalid value -> 0 degrees
            endcase
        end
    end

    assign temp_out = temp_current_reg;

endmodule

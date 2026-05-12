// Module: electric_oven_top
// Description: Top-level module for the electric oven DUT.
//              Integrates APB register block, timer, temperature, operating mode
//              FSM, and ready/LED logic.

module electric_oven_top #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input logic clk,
    input logic reset,         // Active-high reset
    input logic door,          // 1 = door closed, 0 = door open

    // APB Interface
    input  logic [ADDR_WIDTH-1:0] paddr,
    input  logic                  pwrite,
    input  logic                  psel,
    input  logic                  penable,
    input  logic [DATA_WIDTH-1:0] pwdata,
    output logic [DATA_WIDTH-1:0] prdata,
    output logic                  pready,

    // LED output (called 'ready' in the specification)
    output logic led
);

    // Internal register declarations
    reg [7:0] temp_set_reg;
    reg [7:0] operation_mod_reg;
    reg [7:0] timer_reg;

    // APB helper signals used for ACCESS phase detection
    logic prev_psel;
    logic prev_penable;

    // Internal wires connecting submodules
    wire [7:0] temp_out;
    wire [7:0] timer_remain;
    wire       timeout;
    wire       COOK;
    wire       HEAT;
    wire       PIZZA;
    wire       DEFROST;

    // APB register write/read logic.
    // pready is asserted in the ACCESS phase (psel && penable) to conform to the APB spec.
    // Register addresses: 0x00 = temp_set_reg, 0x01 = operation_mod_reg, 0x02 = timer_reg.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            temp_set_reg <= 8'b00000000;
            timer_reg    <= 8'b00000000;
            prdata       <= 8'b00000000;
        end else begin
            if (psel && penable) begin
                case (paddr[1:0])  // Only lower 2 bits are meaningful for 3 registers
                    2'b00: begin
                        if (pwrite) begin
                            temp_set_reg <= pwdata;
                            $display("%0t [DUT-REG] WRITE temp_set_reg = 0x%0h", $time(), pwdata);
                        end else begin
                            prdata <= temp_set_reg;
                            $display("%0t [DUT-REG] READ temp_set_reg = 0x%0h", $time(), temp_set_reg);
                        end
                    end
                    2'b01: begin
                        if (!pwrite) begin
                            prdata <= operation_mod_reg;
                            $display("%0t [DUT-REG] READ operation_mod_reg = 0x%0h", $time(), operation_mod_reg);
                        end
                        // Write to operation_mod_reg is handled in its own always block below
                    end
                    2'b10: begin
                        if (pwrite) begin
                            timer_reg <= pwdata;
                            $display("%0t [DUT-REG] WRITE timer_reg = 0x%0h", $time(), pwdata);
                        end else begin
                            prdata <= timer_reg;
                            $display("%0t [DUT-REG] READ timer_reg = 0x%0h", $time(), timer_reg);
                        end
                    end
                    default: begin
                        $display("%0t [DUT-REG] WARNING: Invalid address 0x%0h", $time(), paddr);
                    end
                endcase
            end
        end
    end

    // Separate always block for operation_mod_reg so that bit 3 (start) can be
    // auto-cleared to 0 one clock cycle after the APB write.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            operation_mod_reg <= 8'b00000000;
        end else begin
            if (psel && penable && paddr[1:0] == 2'b01 && pwrite) begin
                operation_mod_reg <= pwdata;
                $display("%0t [DUT-REG] WRITE operation_mod_reg = 0x%0h (start=%0b, mode=%0b)",
                         $time(), pwdata, pwdata[3], pwdata[2:0]);
            end else begin
                // Hardware auto-clear of start bit (bit 3) every cycle it is not being written
                operation_mod_reg[3] <= 1'b0;
            end
        end
    end

    // pready generation: asserted for exactly one clock cycle when entering ACCESS phase.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_psel    <= 1'b0;
            prev_penable <= 1'b0;
        end else begin
            prev_psel    <= psel;
            prev_penable <= penable;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pready <= 1'b0;
        end else begin
            // Detect rising edge of penable while psel is high (start of ACCESS phase)
            if (psel && penable && !prev_penable) begin
                pready <= 1'b1;
            end else begin
                pready <= 1'b0;
            end
        end
    end

    // Temperature conversion submodule
    temp temp_inst (
        .reset   (reset),
        .clk     (clk),
        .temp_set(temp_set_reg),
        .temp_out(temp_out)
    );

    // Countdown timer submodule
    timer timer_inst (
        .clk          (clk),
        .reset        (reset),
        .start        (operation_mod_reg[3]),
        .timer        (timer_reg),
        .timer_remain (timer_remain),
        .timeout      (timeout)
    );

    // Operating mode FSM submodule
    operation_mod operation_mod_inst (
        .clock  (clk),
        .reset  (reset),
        .req    (operation_mod_reg),
        .COOK   (COOK),
        .HEAT   (HEAT),
        .PIZZA  (PIZZA),
        .DEFROST(DEFROST)
    );

    // Ready/LED combinational logic submodule
    mod_ready mod_ready_inst (
        .COOK        (COOK),
        .HEAT        (HEAT),
        .PIZZA       (PIZZA),
        .DEFROST     (DEFROST),
        .temp_out    (temp_out),
        .timeout     (timeout),
        .door        (door),
        .mod_ready   (led),
        .timer_remain(timer_remain)
    );

    // Debug logging: prints the full DUT state on every active clock edge.
    always @(posedge clk) begin
        if (!reset) begin
            $display("%0t [DUT-STATE] mode_reg=0x%0h temp_reg=0x%0h timer_reg=0x%0h | COOK=%0b HEAT=%0b PIZZA=%0b DEFROST=%0b | temp_out=%0d timeout=%0b timer_remain=%0d door=%0b led=%0b",
                     $time(), operation_mod_reg, temp_set_reg, timer_reg,
                     COOK, HEAT, PIZZA, DEFROST,
                     temp_out, timeout, timer_remain, door, led);
        end
    end

endmodule

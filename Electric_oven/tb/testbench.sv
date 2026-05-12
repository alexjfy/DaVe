// Testbench Top
// Description: Top-level testbench module. Instantiates the DUT, the three
//              verification interfaces (APB, door, LED), the clock/reset
//              generators, and the selected test program.

// Global parameters used by both the DUT and the verification environment.
`include "defines.sv"

// Verification interfaces
`include "apb_interface.sv"
`include "door_interface.sv"
`include "led_interface.sv"

// Select which test to run (uncomment exactly ONE at a time):
// `include "random_test.sv"
// `include "reg_test.sv"
`include "operation_mod_test.sv"
// `include "temperature_test.sv"
// `include "time_reg_test.sv"
// `include "time_modop_test.sv"

module electric_oven_top_tb;

    // Clock period in simulation time units (50 MHz equivalent if units = 1 ns).
    localparam CLK_PERIOD = 20;

    // Clock and reset signals, driven by the testbench initial block below.
    logic clk;
    logic reset;

    // Instantiate the verification interfaces.
    apb_interface  apb_intf(clk, reset);
    door_interface door_intf(clk, reset);
    led_interface  led_intf(clk, reset);

    // Instantiate the DUT and wire it to the interface signals.
    electric_oven_top #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH)
    ) dut (
        .clk     (clk),
        .reset   (reset),
        .door    (door_intf.door_closed),
        .paddr   (apb_intf.paddr),
        .pwrite  (apb_intf.pwrite),
        .psel    (apb_intf.psel),
        .penable (apb_intf.penable),
        .pwdata  (apb_intf.pwdata),
        .prdata  (apb_intf.prdata),
        .pready  (apb_intf.pready),
        .led     (led_intf.led)
    );

    // Clock generator: toggles clk every half period.
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Reset sequence: active-high reset held for 50 time units, then released.
    initial begin
        clk   = 0;
        reset = 1;
        $display("%0t [TB] Reset asserted (active high)", $time());
        #50;
        reset = 0;
        $display("%0t [TB] Reset deasserted - simulation running", $time());
    end

    // Instantiate the test program (the specific one selected above).
    test t1(apb_intf, door_intf, led_intf);

    // Waveform dump for post-simulation inspection.
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

endmodule

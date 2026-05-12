// APB Interface
// Description: SystemVerilog interface for the APB bus.
//              Contains clocking blocks for driver and monitor, modports for
//              role-based access, and APB protocol assertions that fire as
//              warnings or errors when the protocol is violated.
`include "defines.sv"

interface apb_interface(input logic clk, reset);

    // Bus signals (widths taken from defines.sv).
    logic [`ADDR_WIDTH-1:0]  paddr;
    logic                    psel;
    logic                    penable;
    logic                    pwrite;
    logic [`DATA_WIDTH-1:0]  pwdata;
    logic                    pready;
    logic [`DATA_WIDTH-1:0]  prdata;

    // Driver clocking block: drives outputs one time unit after the clock edge
    // and samples inputs one time unit before the clock edge to avoid races.
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output paddr;
        output psel;
        output penable;
        output pwrite;
        output pwdata;
        input  pready;
        input  prdata;
    endclocking

    // Monitor clocking block: samples every signal one time unit before the
    // clock edge so the observed values are stable.
    clocking monitor_cb @(posedge clk);
        default input #1 output #1;
        input paddr;
        input psel;
        input penable;
        input pwrite;
        input pwdata;
        input pready;
        input prdata;
    endclocking

    // Modports restrict access to clocking blocks by role.
    modport DRIVER  (clocking driver_cb,  input clk, reset);
    modport MONITOR (clocking monitor_cb, input clk, reset);

    // APB protocol assertions. All use "disable iff(reset)" because reset is
    // active-high in this design and the bus is not expected to follow the
    // protocol while held in reset.

    // After PSEL rises, PENABLE must rise on the very next clock cycle
    // (APB SETUP -> ACCESS transition).
    property psel_and_penable_active;
        @(posedge clk) disable iff(reset)
        $rose(psel) |-> ##1 $rose(penable);
    endproperty
    assert property (psel_and_penable_active)
        else $warning("%0t [APB-ASSERT] psel_and_penable_active FAILED", $time());

    // When PSEL falls, PREADY must also fall in the same cycle (end of transfer).
    property pready_after_psel_falls;
        @(posedge clk) disable iff(reset)
        $fell(psel) |-> $fell(pready);
    endproperty
    assert property (pready_after_psel_falls)
        else $warning("%0t [APB-ASSERT] pready_after_psel_falls FAILED", $time());

    // PWDATA must be a known value (no X or Z) whenever a write transfer is ongoing.
    property pwdata_not_unknown_on_write;
        @(posedge clk) disable iff(reset)
        (psel && pwrite) |-> !$isunknown(pwdata);
    endproperty
    assert property (pwdata_not_unknown_on_write)
        else $error("%0t [APB-ASSERT] pwdata is unknown (X/Z) during write!", $time());

    // PREADY must be asserted for only one clock cycle at a time.
    property pready_ends;
        @(posedge clk) disable iff(reset)
        pready |=> (!pready);
    endproperty
    assert property (pready_ends)
        else $warning("%0t [APB-ASSERT] pready_ends FAILED: pready stayed high", $time());

    // PRDATA must be a known value (no X or Z) at the end of a completed read transfer.
    property prdata_not_unknown_on_read;
        @(posedge clk) disable iff(reset)
        (psel && penable && !pwrite && pready) |-> !$isunknown(prdata);
    endproperty
    assert property (prdata_not_unknown_on_read)
        else $error("%0t [APB-ASSERT] prdata is unknown (X/Z) during read!", $time());

endinterface

// SystemVerilog interface for the LED output signal.
// The LED has no driver — it is a read-only DUT output observed by the monitor.
interface led_interface(input logic clk, reset);

  // Signal declaration: 1 = LED on (cooking complete), 0 = LED off.
  logic led;

  // Monitor clocking block: reads led one time unit before the clock edge
  // to capture stable values and avoid race conditions.
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    input led;
  endclocking

  // Modport restricts the monitor to read-only access.
  modport MONITOR (clocking monitor_cb, input clk, reset);

endinterface

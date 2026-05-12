// SystemVerilog interface for the door sensor signal.
// Provides separate clocking blocks for driver and monitor to avoid
// read/write conflicts at the clock edge.
interface door_interface(input logic clk, reset);

  // Signal declaration: 1 = door closed, 0 = door open.
  logic door_closed;

  // Driver clocking block: the driver writes door_closed one time unit after
  // the clock edge to avoid contention with the monitor.
  clocking driver_cb @(posedge clk);
    default input #1 output #1;
    output door_closed;
  endclocking

  // Monitor clocking block: the monitor reads door_closed one time unit before
  // the clock edge to capture stable values.
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    input door_closed;
  endclocking

  // Modports restrict which signals each role can access.
  modport DRIVER  (clocking driver_cb,  input clk, reset);
  modport MONITOR (clocking monitor_cb, input clk, reset);

endinterface

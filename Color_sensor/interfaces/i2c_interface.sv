`ifndef I2C_INTERFACE_SV
`define I2C_INTERFACE_SV

interface i2c_interface (input clk, input rst_n);

  // Signals
  logic scl;       // serial clock
  logic sda;       // serial data (read from wire)
  logic sda_drive; // slave drive output (active-low for ACK)

  initial sda_drive = 1'b1;

  reg stable_assertion_enable; // set when SCL is HIGH
  reg trans_enable           ; // set when a transfer happens
  reg trans_enable_d = 0     ; // delayed trans_enable (for assertion gating)
  reg post_reset = 0         ; // suppresses assertions before first reset

  // Clocking blocks
  // Slave
  clocking s_cb @(posedge clk);
    input  scl;
    input  sda;
    output sda_drive;
  endclocking:s_cb

  // Monitor
  clocking mon_cb @(posedge clk);
    input scl;
    input sda;
  endclocking:mon_cb

  // Assertions

  initial forever begin
    @(posedge scl);
    //@(negedge clk);
    stable_assertion_enable = 1'b1;
    @(negedge scl);
    stable_assertion_enable = 1'b0;
    //@(posedge clk);
  end

// START = SDA falls while SCL high; STOP = SDA rises while SCL high.
  // Between them a transfer is in progress (trans_enable = 1)
  initial forever begin
    @(negedge sda iff scl === 'b1);
    trans_enable = 1'b1;
    @(posedge sda iff scl === 'b1);
    trans_enable = 1'b0;
  end

// Enable assertions only after the first full reset completes
  initial begin
    @(negedge rst_n);
    @(posedge rst_n);
    @(posedge clk);
    post_reset = 1;
  end

// Delay trans_enable by one cycle; used to exclude the exact
// START/STOP edges from the SDA-stability assertion
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) trans_enable_d <= 0;
    else        trans_enable_d <= trans_enable;
  end
  

  // Signals are never X or Z
  assert property (@(posedge clk) disable iff (!rst_n || !post_reset) !$isunknown(scl))
    else $error("I2C Interface: !!! SCL is unknown !!!");
  assert property (@(posedge clk) disable iff (!rst_n || !post_reset) !$isunknown(sda))
    else $error("I2C Interface: !!! SDA is unknown !!!");

  // SDA doesn't change when SCL is HIGH (excluding START/STOP conditions)
  assert property (@(clk) disable iff (!rst_n || !post_reset) (stable_assertion_enable && trans_enable_d && trans_enable) |-> $stable(sda))
    else $error("I2C Interface: !!! SDA changed when SCL high!!!");

  // SCL makes a full cycle
  assert property (@(posedge clk) disable iff (!rst_n || !post_reset) $fell(scl) |-> ##[0:10000] $rose(scl))
    else $error("I2C Interface: !!! SCL cycle didn't finish !!!");

  // SCL toggles only between START and STOP
  assert property (@(clk) disable iff (!rst_n || !post_reset) !trans_enable |-> $stable(scl))
    else $error("I2C Interface: !!! SCL changed before START!!!");

endinterface:i2c_interface

`endif 

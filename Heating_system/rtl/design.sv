parameter ADDR_WIDTH = 2;
parameter DATA_WIDTH = 8;


module boiler_controller (
  // clock and synchronous reset
  input                         clk     ,
  input                         rst     ,

  // APB slave interface - used to program func_reg
  input                         psel,
  input                         penable,
  input                         pwrite,
  input [ADDR_WIDTH-1:0]        paddr,
  input [DATA_WIDTH-1:0]        pwdata,

  // button inputs from the user panel
  input                         button_econ  ,
  input                         button_comf  ,
  input                         button_thermo  ,
  input                         child_protection, // disables all mode buttons when high

  // outputs
  output                        led     ,    // lit whenever the boiler is running (any state after s0)
  output                        flame,       // active in econ, comf and thermo states
  output                        enable_c,    // enables the sustain counter (econ and comf only)
  output logic                  pready,
  output logic [DATA_WIDTH-1:0] prdata
);

// FSM state and internal registers
reg [2:0] current_state;
reg [2:0] next_state;
reg [3:0]  func_reg;  // bits [2:0] enable thermo/comf/econ modes; written via APB
reg [2:0]   counter;  // counts clock cycles to sustain flame in econ/comf
reg        finish;    // set when the counter reaches the target; forces return to s1
reg [2:0]   data_in;  // target count loaded when entering econ (3) or comf (6)
wire       reset_c;   // clears the counter on every mode transition


// one-hot state encoding
localparam      s0        = 3'b000;  // power-on reset state
localparam      s1        = 3'b001;  // idle / mode selection
localparam      econ      = 3'b010;  // economy mode  (short flame burst: target=3)
localparam      comf      = 3'b011;  // comfort mode  (longer flame burst: target=6)
localparam      thermo = 3'b100;     // thermostat mode (flame held while button pressed)

// start is always 1 in this design, so s0->s1 happens on the first clock after reset
wire start;
assign start = 1;

// sequential: update state on every rising edge; reset to s0
always @(posedge clk or posedge rst)
  if (rst) current_state <= s0;
  else     current_state <= next_state;

// combinational next-state logic
// a button press is only accepted when: the button is high, child_protection is low,
// and the corresponding bit in func_reg enables that mode
always @(*)
case (current_state)
  s0    :  if (start) next_state = s1;
           else       next_state = s0;

  s1 :     if      (button_econ  && !child_protection && func_reg[0]) next_state = econ;
           else if (button_comf  && !child_protection && func_reg[1]) next_state = comf;
           else if (button_thermo && !child_protection && func_reg[2]) next_state = thermo;
           else next_state = s1;

  // econ: direct jump to comf is allowed; releasing the button OR counter expiry returns to s1
  econ :   if      (button_comf && !child_protection && func_reg[1])                next_state = comf;
           else if ((!button_econ && !child_protection && func_reg[0]) || finish)   next_state = s1;
           else next_state = econ;

  // comf: symmetric to econ
  comf :   if      (button_econ && !child_protection && func_reg[0])                next_state = econ;
           else if ((!button_comf && !child_protection && func_reg[1]) || finish)   next_state = s1;
           else next_state = comf;

  // thermo: stays active while the button is held; no counter used
  thermo : if (!button_thermo && !child_protection && func_reg[2]) next_state = s1;
           else next_state = thermo;

  default : next_state = s1;
endcase

// combinational outputs
assign led      = (current_state != s0);  // green LED on whenever boiler is not in reset state
assign flame    = (current_state == econ || current_state == comf || current_state == thermo);
assign enable_c = (current_state == econ || current_state == comf);  // counter runs only in timed modes

// reset_c: pulse high on any transition that starts a new timed burst
// this clears the counter so we always count from zero when entering a mode
assign reset_c  = (current_state == s1   && next_state == econ) ||
                  (current_state == s1   && next_state == comf) ||
                  (current_state == econ && next_state == comf) ||
                  (current_state == comf && next_state == econ);

// load the flame-sustain target for the next state (registered one cycle early)
always @(posedge clk or posedge rst)
begin
    if (rst) begin
        data_in <= 0;
    end
    else if (next_state == econ) begin
        data_in <= 3;  // economy: shorter burst
    end
    else if (next_state == comf) begin
        data_in <= 6;  // comfort: longer burst
    end
end

// up-counter that tracks how many cycles the current mode has been active
// when counter reaches data_in, finish is asserted and the FSM returns to s1
always @(posedge clk or posedge rst)
begin
    if (rst) begin
        counter <= 0;
        finish  <= 0;
    end
    else if (reset_c) begin
        // clear on every mode entry so we start counting fresh
        counter <= 0;
        finish  <= 0;
    end
    else if (enable_c) begin
        if (counter == data_in) begin
            finish  <= 1;  // signal the FSM to return to s1
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end
end

// APB slave - only address 0x00 is used (func_reg)
// pready is asserted for one cycle during the access phase (psel high, penable low)
always @(posedge clk or posedge rst)
  if (rst)
    pready <= 0;
  else if (psel && !penable)
    pready <= 1;
  else
    pready <= 0;

// read: return func_reg contents on address 0
always @(posedge clk or posedge rst)
  if (rst)
    prdata <= 0;
  else if (psel && !penable && !pwrite && (paddr == 0))
    prdata <= func_reg;

// write: update func_reg on address 0
always @(posedge clk or posedge rst)
  if (rst)
    func_reg <= 0;
  else if (pwrite && psel && !penable && (paddr == 0))
    func_reg <= pwdata;

//debug prints
always @(posedge clk) begin
  if (!rst && current_state != next_state)
    $display("[%0t] state: %0d -> %0d", $time, current_state, next_state);
end

always @(posedge clk) begin
    if (!rst && psel && !penable && pwrite && (paddr == 0))
        $display("[%0t] apb write func_reg=0x%0h", $time, pwdata[3:0]);
    if (!rst && psel && !penable && !pwrite && (paddr == 0))
        $display("[%0t] apb read func_reg=0x%0h", $time, func_reg);
end

always @(posedge clk) begin
    if (!rst && enable_c)
        $display("[%0t] counter=%0d/%0d finish=%0b", $time, counter, data_in, finish);
end

// flame and led changes
always @(flame) $display("[%0t] flame=%0b", $time, flame);
always @(led)     $display("[%0t] led=%0b", $time, led);

always @(posedge clk) begin
  if (!rst && (button_econ || button_comf || button_thermo || child_protection))
    $display("[%0t] buttons: e=%b c=%b t=%b prot=%b reg=%b state=%0d",
             $time, button_econ, button_comf, button_thermo, child_protection, func_reg, current_state);
end

endmodule
`timescale 1ns/1ps

// Controller board DUT for the car lever (maneta auto).
// Implements the APB slave protocol and drives the outputs for:
//   - high beam
//   - left / right turn signals
//   - flash (momentary high beam)
//   - windshield washer
//   - wipers, manual or automatic (rain sensor) with PWM duty cycle
//
// Register map:
//   addr 0 (lever_reg)      - bitfield controlling which features are active
//   addr 1 (cfg_APB_reg)    - APB configuration register (reserved/config)
//   addr 2 (rain_level_reg) - rain sensor value, used in wipers automatic mode
//
// lever_reg bit layout:
//   [7]   wipers mode: 0 = manual, 1 = automatic
//   [6]   washer on/off
//   [5]   flash trigger (auto-cleared by DUT after 3 clock cycles)
//   [4]   high beam on/off
//   [3]   right signal on/off
//   [2]   left signal on/off
//   [1:0] wipers manual duty cycle: 00=0%, 01=25%, 10=75%, 11=100%

module controller_board
#(
   parameter ADDR_WIDTH = 2,
   parameter DATA_WIDTH = 8
)
(
   input clk,
   input reset,

   //APB control signals
   input [ADDR_WIDTH-1:0] paddr_i,
   input pwrite_i,
   input penable_i,
   input psel_i,

   //APB data signals
   input  [DATA_WIDTH-1:0] pwdata_i,
   output reg [DATA_WIDTH-1:0] prdata_o,
   output reg pready_o,

   //DUT outputs to the car electrical system
   output reg high_beam_o,
   output reg left_signal_o,
   output reg right_signal_o,
   output reg flash_o,
   output reg washer_o,
   output reg wipers_o
);

   // Free-running 2-bit counter used as timebase for PWM (wipers) and flash duration.
   // Rolls over every 4 clock cycles.
   reg [1:0] counter_clk = 0;

   // Internal register file
   reg [DATA_WIDTH-1:0] lever_reg;         // address 0 - lever control bits
   reg [DATA_WIDTH-1:0] cfg_APB_reg;       // address 1 - APB configuration
   reg [DATA_WIDTH-1:0] rain_level_reg;    // address 2 - rain sensor (0..255)

   // Used to latch the counter_clk value at which flash_o should go low
   // (3 cycles after activation, so modulo-4 of counter+3)
   reg [1:0] counter_target;


   // APB write logic: captures pwdata_i into the addressed register when
   // psel, pwrite and penable are all asserted (APB access phase).
   always @(posedge clk or posedge reset) begin
      if (reset) begin
         lever_reg       <= 8'h00;
         cfg_APB_reg     <= 8'h00;
         rain_level_reg  <= 8'h00;
         $display("[DUT] reset: all registers cleared to 0x00");
      end
      else begin
         if (pwrite_i == 1 && psel_i == 1 && penable_i == 1) begin
            case (paddr_i)
               2'h0: begin
                  lever_reg <= pwdata_i;
                  $display("[DUT] write lever_reg[0x0] = 0x%0h (%08b)", pwdata_i, pwdata_i);
               end
               2'h1: begin
                  cfg_APB_reg <= pwdata_i;
                  $display("[DUT] write cfg_APB_reg[0x1] = 0x%0h", pwdata_i);
               end
               2'h2: begin
                  rain_level_reg <= pwdata_i;
                  $display("[DUT] write rain_level_reg[0x2] = %0d", pwdata_i);
               end
            endcase
         end
         // Auto-clear the flash trigger bit once flash_o has been driven high.
         // This is what makes flash a momentary signal even if the user keeps writing 1.
         if (flash_o == 1'b1)
            lever_reg[5] <= 1'b0;
      end
   end


   // APB read logic: returns the addressed register on prdata_o during the access phase.
   always @(posedge clk or posedge reset) begin
      if (reset)
         prdata_o <= 0;
      else if (psel_i == 1 && pwrite_i == 0 && penable_i == 1) begin
         case (paddr_i)
            2'h0: begin
               prdata_o <= lever_reg;
               $display("[DUT] read lever_reg[0x0] = 0x%0h", lever_reg);
            end
            2'h1: begin
               prdata_o <= cfg_APB_reg;
               $display("[DUT] read cfg_APB_reg[0x1] = 0x%0h", cfg_APB_reg);
            end
            2'h2: begin
               prdata_o <= rain_level_reg;
               $display("[DUT] read rain_level_reg[0x2] = %0d", rain_level_reg);
            end
            default: prdata_o <= {DATA_WIDTH{1'bx}};
         endcase
      end
   end


   // High beam is directly controlled by lever_reg[4]
   always @(posedge clk or posedge reset) begin
      if (reset)
         high_beam_o <= 0;
      else if (lever_reg[4] == 1)
         high_beam_o <= 1;
      else
         high_beam_o <= 0;
   end


   // Right turn signal is controlled by lever_reg[3]
   always @(posedge clk or posedge reset) begin
      if (reset)
         right_signal_o <= 0;
      else if (lever_reg[3] == 1)
         right_signal_o <= 1;
      else
         right_signal_o <= 0;
   end


   // Left turn signal is controlled by lever_reg[2].
   // If both lever_reg[3] and lever_reg[2] are 1 we get hazard lights (both signals on).
   always @(posedge clk or posedge reset) begin
      if (reset)
         left_signal_o <= 0;
      else if (lever_reg[2] == 1)
         left_signal_o <= 1;
      else
         left_signal_o <= 0;
   end


   // Flash output is momentary: triggered by lever_reg[5]=1, stays high for 3 cycles, then clears.
   // The target cycle (when flash should go low) is computed as (counter_clk + 3) mod 4.
   // Because counter_clk is 2 bits it wraps naturally.
   always @(posedge clk or posedge reset) begin
      if (reset) begin
         flash_o <= 0;
         counter_target <= 0;
      end
      else if (lever_reg[5] == 1) begin
         if (flash_o == 0) begin
            counter_target <= (counter_clk + 3) % 4;
            flash_o <= 1;
            $display("[DUT] flash: ON for 3 cycles (counter=%0d, target=%0d)", counter_clk, (counter_clk + 3) % 4);
         end
      end
      else if (counter_clk == counter_target) begin
         if (flash_o == 1)
            $display("[DUT] flash: OFF (counter reached target=%0d)", counter_target);
         flash_o <= 0;
      end
   end


   // Washer is directly controlled by lever_reg[6]
   always @(posedge clk or posedge reset) begin
      if (reset)
         washer_o <= 0;
      else if (lever_reg[6] == 1)
         washer_o <= 1;
      else
         washer_o <= 0;
   end


   // Wipers output - PWM controlled by lever_reg[7] (mode selector)
   //   mode 0 (manual):    duty cycle comes from lever_reg[1:0]
   //   mode 1 (automatic): duty cycle derived from rain_level_reg thresholds
   //
   // PWM implementation: over a 4-cycle window (counter_clk 0..3),
   //   25% -> wipers high only when counter_clk==3 (1 of 4 cycles)
   //   75% -> wipers high except when counter_clk==1 (3 of 4 cycles)
   //    0% and 100% are constant low / high respectively.
   always @(posedge clk or posedge reset) begin
      if (reset)
         wipers_o <= 1'b0;
      else if (lever_reg[7] == 0) begin
         // Manual mode: lever_reg[1:0] selects the duty cycle directly
         if (lever_reg[1:0] == 2'b00) begin         // duty cycle 0%
            wipers_o <= 1'b0;
         end
         else if (lever_reg[1:0] == 2'b01) begin    // duty cycle 25%
            if (counter_clk == 3)
               wipers_o <= 1;
            else
               wipers_o <= 0;
         end
         else if (lever_reg[1:0] == 2'b10) begin    // duty cycle 75%
            if (counter_clk == 1)
               wipers_o <= 0;
            else
               wipers_o <= 1;
         end
         else if (lever_reg[1:0] == 2'b11) begin    // duty cycle 100%
            wipers_o <= 1;
         end
      end
      else begin
         // Automatic mode: rain sensor value selects one of 4 PWM levels.
         // Thresholds:
         //   0..44    -> 0%   (almost dry, no wipers)
         //   45..124  -> 25%  (light rain)
         //   125..214 -> 75%  (moderate/heavy rain)
         //   215..255 -> 100% (continuous, very heavy rain)
         if (rain_level_reg < 45) begin
            wipers_o <= 1'b0;
         end
         else if (rain_level_reg >= 45 && rain_level_reg <= 124) begin
            if (counter_clk == 3)
               wipers_o <= 1;
            else
               wipers_o <= 0;
         end
         else if (rain_level_reg >= 125 && rain_level_reg <= 214) begin
            if (counter_clk == 1)
               wipers_o <= 0;
            else
               wipers_o <= 1;
         end
         else if (rain_level_reg >= 215) begin
            wipers_o <= 1;
         end
      end
   end


   // Free-running modulo-4 counter, used as timebase by flash and wipers PWM
   always @(posedge clk or posedge reset) begin
      if (reset)
         counter_clk <= 0;
      else
         counter_clk <= (counter_clk + 1) % 4;
   end


   // APB pready generation: pulse high for one cycle after psel is asserted,
   // then drop low (slave is always ready, single-cycle response).
   always @(posedge clk or posedge reset) begin
      if (reset)
         pready_o <= 0;
      else if (pready_o == 1)
         pready_o <= 0;
      else if (psel_i == 1)
         pready_o <= 1;
      else
         pready_o <= 0;
   end

endmodule

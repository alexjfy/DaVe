`include "LIFO_buffer.sv"

module op_controller #(
parameter RESULT_WIDTH  = 16,
parameter REG_WIDTH     = 8,
parameter DATA_WIDTH    = 9
) (
  input                           clk         , // System clock
  input                           preset      , // System reset
  input                           start       , // Start operation (from CONTROL reg bit 2)
  input                           stop        , // Stop operation (from CONTROL reg bit 3)
  input       [DATA_WIDTH -1:0]   data        , // FIFO output: bit[8]=1 means opcode, =0 means operand
  input       [REG_WIDTH -1:0]    divider     , // Clock divider (unused for now)
  input       [REG_WIDTH -1:0]    reg_config  , // Enable/ignore bits for each operation
  input                           empty       , // FIFO empty flag
  output      [RESULT_WIDTH -1:0] result      , // Result of the postfix computation
  output                          valid       , // Result is valid
  output                          fifo_re     , // Read enable for the input FIFO
  output                          overflow    , // Arithmetic overflow detected
  output                          bsy         , // Busy signal while computation runs
  output                          done        , // Computation finished OK
  output                          fail          // Computation failed (div0, stop, config, etc.)

);

// FSM states
// IDLE -> BSY -> LOAD0/LOAD1 (push operands) -> POP0/POP1 (pop two operands)
//      -> <op> (compute) -> LOAD0 (push result back) ... until FIFO empty -> STOP
localparam STATE_SIZE       = 16;
localparam ST_IDLE          = 0;
localparam ST_BSY           = 1;
localparam ST_ADD       = 2;
localparam ST_SUB       = 3;
localparam ST_MUL     = 4;
localparam ST_DIV     = 5;
localparam ST_MOD        = 6;
localparam ST_SHIFT_LEFT    = 7;
localparam ST_SHIFT_RIGHT   = 8;
localparam ST_STOP          = 9;
localparam ST_FAIL          = 10;
localparam ST_LOAD0         = 11;
localparam ST_LOAD1         = 12;
localparam ST_POP0          = 13;
localparam ST_POP1          = 14;
localparam ST_OVERFLOW      = 15;

// Opcodes coming from the FIFO. bit[8]=1 is the marker that says "this is an opcode,
// not an operand"; bits [7:0] match the OPERATIONS register layout (one-hot).
parameter ADD      = 9'h101;
parameter SUB      = 9'h102;
parameter MUL    = 9'h104;
parameter DIV    = 9'h108;
parameter MOD       = 9'h110;
parameter SHIFT_LEFT   = 9'h120;
parameter SHIFT_RIGHT  = 9'h140;

// CONFIG register masks - if bit is set, that operation is ignored and
// the controller goes to FAIL when it encounters it
localparam IGNORE_ADD     = 8'h01;
localparam IGNORE_SUB     = 8'h02;
localparam IGNORE_MUL   = 8'h04;
localparam IGNORE_DIV   = 8'h08;
localparam IGNORE_MOD      = 8'h10;
localparam IGNORE_SHIFT_LEFT  = 8'h20;
localparam IGNORE_SHIFT_RIGHT = 8'h40;

reg [STATE_SIZE -1:0]   c_state;
reg [STATE_SIZE -1:0]   next_state;
reg [RESULT_WIDTH -1:0] result_o;
reg [RESULT_WIDTH -1:0] operand0;
reg [RESULT_WIDTH -1:0] operand1;
reg  valid_o;
reg  fifo_re_o;
reg  done_o;
reg  fail_o;
reg  bsy_o;
reg [DATA_WIDTH -1:0]   data_o;

reg lifo_we;
reg lifo_re;
reg lifo_clear;

reg result_we;
reg overflow_o;

wire [RESULT_WIDTH -1:0] lifo_data_out;
wire lifo_empty;
wire lifo_full;

LIFO_buffer #(
  .DATA_WIDTH(16),
  .DEPTH(256)
) lifo(
  .clk(clk),
  .clear(lifo_clear),
  .we(lifo_we),
  .re(lifo_re),
  .data_in((result_we) ? (result_o) : {7'b0,data_o}),
  .data_out(lifo_data_out),
  .empty(lifo_empty),
  .full(lifo_full)
);

// Current state is registered, next_state is combinational below
always @(posedge clk or posedge preset) begin
  if(preset)  c_state <= ST_IDLE; else
              c_state <= next_state;
end

assign valid    = valid_o;
assign result   = result_o;
assign fifo_re  = fifo_re_o;
assign done     = done_o;
assign fail     = fail_o;
assign bsy      = bsy_o;
assign overflow = overflow_o;


always @(*) begin
  case(c_state)
    ST_IDLE:  begin
      result_o      = 'b0;
      bsy_o         = 1'b0;
      valid_o       = 1'b0;
      fifo_re_o     = 1'b0;
      done_o        = 1'b0;
      fail_o        = 1'b0;
      lifo_re       = 1'b0;
      lifo_we       = 1'b0;
      lifo_clear    = 1'b1;
      result_we     = 1'b0;
      data_o        = 'b0;
      overflow_o    = 1'b0;
      if(start) begin
        next_state  = ST_BSY;
        $display("T=%0t [OP_CTRL] START received, moving to BSY", $time);
      end else
        next_state  = ST_IDLE;
    end

    ST_BSY: begin
      lifo_clear  = 1'b0;
      result_we   = 1'b0;
      if(stop) begin
        next_state = ST_FAIL;
        lifo_clear = 1'b1;
        $display("T=%0t [OP_CTRL] STOP received, moving to FAIL", $time);
      end
      else begin
        lifo_we     = 1'b1;
        fifo_re_o   = 1'b1;
        bsy_o       = 1'b1;
        next_state  = ST_LOAD0;
      end
    end

    // data[8] distinguishes operands (0) from opcodes (1).
    // If it's an operand, push to LIFO and alternate LOAD0<->LOAD1 to pipeline
    // the FIFO read. If it's an opcode, stop reading and go pop two operands.
    ST_LOAD0: begin
      if(data[8] != 1'b1) begin
        data_o      = data;
        next_state  = ST_LOAD1;
        result_we   = 1'b0;
        $display("T=%0t [OP_CTRL] LOAD0: data=%0d pushed to LIFO", $time, data[7:0]);
      end else begin
        fifo_re_o   = 1'b0;
        lifo_re     = 1'b1;
        lifo_we     = 1'b0;
        next_state  = ST_POP0;
        $display("T=%0t [OP_CTRL] LOAD0: operation 0x%0h detected, popping operands", $time, data);
      end
    end

    ST_LOAD1: begin
      if(data[8] != 1'b1) begin
        data_o      = data;
        lifo_we     = 1'b1;
        next_state  = ST_LOAD0;
        $display("T=%0t [OP_CTRL] LOAD1: data=%0d pushed to LIFO", $time, data[7:0]);
      end else begin
        fifo_re_o   = 1'b0;
        lifo_re     = 1'b1;
        lifo_we     = 1'b0;
        next_state  = ST_POP0;
        $display("T=%0t [OP_CTRL] LOAD1: operation 0x%0h detected, popping operands", $time, data);
      end
    end

    // Pop two operands from the LIFO.
    // Careful: LIFO is LIFO, so operand1 (the one popped second) is actually
    // the LHS of the infix expression, operand0 is the RHS.
    //   postfix "A B +"   => push A, push B, pop op0=B, pop op1=A, result=A+B
    ST_POP0: begin
      operand0    = lifo_data_out;
      next_state  = ST_POP1;
      $display("T=%0t [OP_CTRL] POP0: operand0=%0d", $time, lifo_data_out);
    end

    ST_POP1: begin
      operand1  = lifo_data_out;
      lifo_re   = 1'b0;
      $display("T=%0t [OP_CTRL] POP1: operand1=%0d", $time, lifo_data_out);
      case(data)
        ADD: begin
          if(reg_config & IGNORE_ADD) begin next_state = ST_FAIL; $display("T=%0t [OP_CTRL] ADD ignored by CONFIG (0x%0h)", $time, reg_config); end
          else begin next_state = ST_ADD; $display("T=%0t [OP_CTRL] -> ADD", $time); end
        end
        SUB: begin
          if(reg_config & IGNORE_SUB) begin next_state = ST_FAIL; $display("T=%0t [OP_CTRL] SUB ignored by CONFIG (0x%0h)", $time, reg_config); end
          else begin next_state = ST_SUB; $display("T=%0t [OP_CTRL] -> SUB", $time); end
        end
        MUL: begin
          if(reg_config & IGNORE_MUL) begin next_state = ST_FAIL; $display("T=%0t [OP_CTRL] MUL ignored by CONFIG (0x%0h)", $time, reg_config); end
          else begin next_state = ST_MUL; $display("T=%0t [OP_CTRL] -> MUL", $time); end
        end
        DIV: begin
          if(reg_config & IGNORE_DIV) begin next_state = ST_FAIL; $display("T=%0t [OP_CTRL] DIV ignored by CONFIG (0x%0h)", $time, reg_config); end
          else begin next_state = ST_DIV; $display("T=%0t [OP_CTRL] -> DIV", $time); end
        end
        MOD: begin
          if(reg_config & IGNORE_MOD) begin next_state = ST_FAIL; $display("T=%0t [OP_CTRL] MOD ignored by CONFIG (0x%0h)", $time, reg_config); end
          else begin next_state = ST_MOD; $display("T=%0t [OP_CTRL] -> MOD", $time); end
        end
        SHIFT_LEFT: begin
          if(reg_config & IGNORE_SHIFT_LEFT) begin next_state = ST_FAIL; $display("T=%0t [OP_CTRL] SHL ignored by CONFIG (0x%0h)", $time, reg_config); end
          else begin next_state = ST_SHIFT_LEFT; $display("T=%0t [OP_CTRL] -> SHL", $time); end
        end
        SHIFT_RIGHT: begin
          if(reg_config & IGNORE_SHIFT_RIGHT) begin next_state = ST_FAIL; $display("T=%0t [OP_CTRL] SHR ignored by CONFIG (0x%0h)", $time, reg_config); end
          else begin next_state = ST_SHIFT_RIGHT; $display("T=%0t [OP_CTRL] -> SHR", $time); end
        end
        default: begin
          next_state = ST_FAIL;
          $display("T=%0t [OP_CTRL] -> UNKNOWN OP (0x%0h), FAIL", $time, data);
        end
      endcase
    end

    ST_ADD: begin
      result_o = operand1 + operand0;
      $display("T=%0t [OP_CTRL] ADD: %0d + %0d = %0d", $time, operand1, operand0, result_o);
      // Unsigned add overflow check: if the sum wrapped around, result < operand1
      if(result_o < operand1) begin
        overflow_o  = 1'b1;
        next_state  = ST_OVERFLOW;
        $display("T=%0t [OP_CTRL] OVERFLOW in ADD", $time);
      end else if(empty) begin
        fifo_re_o   = 1'b0;
        next_state  = ST_STOP;
      end else begin
        lifo_we     = 1'b1;
        result_we   = 1'b1;
        fifo_re_o   = 1'b1;
        next_state  = ST_LOAD0;
      end
    end

    ST_SUB: begin
      result_o = operand1 - operand0;
      $display("T=%0t [OP_CTRL] SUB: %0d - %0d = %0d", $time, operand1, operand0, result_o);
      if(empty) begin
        fifo_re_o   = 1'b0;
        next_state  = ST_STOP;
      end else begin
        lifo_we     = 1'b1;
        result_we   = 1'b1;
        fifo_re_o   = 1'b1;
        next_state  = ST_LOAD0;
      end
    end

    ST_MUL: begin
      result_o = operand1 * operand0;
      $display("T=%0t [OP_CTRL] MUL: %0d * %0d = %0d", $time, operand1, operand0, result_o);
      // If the product truncated, result becomes smaller than either operand.
      // Skip the check when one of them is 0 (0 * x = 0 is not overflow).
      if(operand1 != 0 && operand0 != 0 && (result_o < operand1 || result_o < operand0)) begin
        overflow_o  = 1'b1;
        next_state  = ST_OVERFLOW;
        $display("T=%0t [OP_CTRL] OVERFLOW in MUL", $time);
      end else if(empty) begin
        fifo_re_o   = 1'b0;
        next_state  = ST_STOP;
      end else begin
        lifo_we     = 1'b1;
        result_we   = 1'b1;
        fifo_re_o   = 1'b1;
        next_state  = ST_LOAD0;
      end
    end

    ST_DIV: begin
      if(operand0 == 0) begin
        next_state = ST_FAIL;
        $display("T=%0t [OP_CTRL] DIV by zero! FAIL", $time);
      end else begin
        result_o = operand1 / operand0;
        $display("T=%0t [OP_CTRL] DIV: %0d / %0d = %0d", $time, operand1, operand0, result_o);
        if(empty) begin
          fifo_re_o   = 1'b0;
          next_state  = ST_STOP;
        end else begin
          lifo_we     = 1'b1;
          result_we   = 1'b1;
          fifo_re_o   = 1'b1;
          next_state  = ST_LOAD0;
        end
      end
    end

    ST_MOD: begin
      if(operand0 == 0) begin
        next_state = ST_FAIL;
        $display("T=%0t [OP_CTRL] MOD by zero! FAIL", $time);
      end else begin
        result_o = operand1 % operand0;
        $display("T=%0t [OP_CTRL] MOD: %0d mod %0d = %0d", $time, operand1, operand0, result_o);
        if(empty) begin
          fifo_re_o   = 1'b0;
          next_state  = ST_STOP;
        end else begin
          lifo_we     = 1'b1;
          result_we   = 1'b1;
          fifo_re_o   = 1'b1;
          next_state  = ST_LOAD0;
        end
      end
    end

    ST_SHIFT_LEFT: begin
      result_o = operand1 << operand0;
      $display("T=%0t [OP_CTRL] SHL: %0d << %0d = %0d", $time, operand1, operand0, result_o);
      if(empty) begin
        fifo_re_o  = 1'b0;
        next_state = ST_STOP;
      end else begin
        lifo_we     = 1'b1;
        result_we   = 1'b1;
        fifo_re_o   = 1'b1;
        next_state  = ST_LOAD0;
      end
    end

    ST_SHIFT_RIGHT: begin
      result_o = operand1 >> operand0;
      $display("T=%0t [OP_CTRL] SHR: %0d >> %0d = %0d", $time, operand1, operand0, result_o);
      if(empty) begin
        fifo_re_o  = 1'b0;
        next_state = ST_STOP;
      end else begin
        lifo_we     = 1'b1;
        result_we   = 1'b1;
        fifo_re_o   = 1'b1;
        next_state  = ST_LOAD0;
      end
    end

    ST_STOP: begin
      done_o      = 1'b1;
      valid_o     = 1'b1;
      fifo_re_o   = 1'b0;
      bsy_o       = 1'b0;
      next_state  = ST_IDLE;
      $display("T=%0t [OP_CTRL] *** DONE *** result=%0d (0x%0h)", $time, result_o, result_o);
    end

    ST_FAIL: begin
      bsy_o       = 1'b0;
      fifo_re_o   = 1'b0;
      fail_o      = 1'b1;
      next_state  = ST_IDLE;
      $display("T=%0t [OP_CTRL] *** FAIL ***", $time);
    end

    // overflow_o was pulsed 1 for one cycle in ST_ADD/ST_MUL so the status
    // register latches the OVERFLOW bit; here we drop it back to 0 and return.
    ST_OVERFLOW: begin
      bsy_o       = 1'b0;
      fifo_re_o   = 1'b0;
      overflow_o  = 1'b0;
      next_state  = ST_IDLE;
      $display("T=%0t [OP_CTRL] *** OVERFLOW ***", $time);
    end
    default: next_state = ST_IDLE;
  endcase
end
endmodule

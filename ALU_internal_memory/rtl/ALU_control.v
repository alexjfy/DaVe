module ALU_control (
    input wire clk,
    input wire reset_n,
    input wire psel,
    input wire penable,
    input wire [31:0] paddr,
    input wire pwrite,
    input wire [31:0] pwdata,
    input wire state,
    output reg [31:0] prdata,
    output reg pready,
    output reg pslverr,
    output reg [8:0] result
);

    reg [31:0] received_data;
    reg init;
    reg endop;
    reg [4:0] currentState, nextState;
    reg load_op, shift_op1, add1, add2, add3, and_op, or_op, nand_op, nor_op, comp;

    reg [7:0] op1;
    reg [7:0] op2;
    reg [3:0] const_val;

    reg [5:0] result_address;

    reg [8:0] ResultReg_0;
    reg [8:0] ResultReg_1;
    reg [8:0] ResultReg_2;
    reg [8:0] ResultReg_3;
    reg [8:0] ResultReg_4;
    reg [8:0] ResultReg_5;
    reg [8:0] ResultReg_6;
    reg [8:0] ResultReg_7;
    reg [8:0] ResultReg_8;
    reg [8:0] ResultReg_9;
    reg [8:0] ResultReg_10;
    reg [8:0] ResultReg_11;
    reg [8:0] ResultReg_12;
    reg [8:0] ResultReg_13;
    reg [8:0] ResultReg_14;
    reg [8:0] ResultReg_15;

    // State encodings
    localparam INIT      = 5'b00000;
    localparam SETUP     = 5'b00001;
    localparam ADD1      = 5'b00010;
    localparam ADD2      = 5'b00011;
    localparam ADD3      = 5'b00100;
    localparam SHIFT_OP1 = 5'b00101;
    localparam OR        = 5'b00110;
    localparam AND       = 5'b00111;
    localparam NOR       = 5'b01000;
    localparam NAND      = 5'b01001;
    localparam COMP      = 5'b01010;
    localparam ENDOP     = 5'b01011;

    // APB block: handles the handshake, init, pready, pslverr,
    // pwdata capture and prdata readout.
    // Single driver for init, pslverr, pready, received_data and prdata.
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pready        <= 1'b0;
            pslverr       <= 1'b0;
            init          <= 1'b0;
            received_data <= 32'b0;
            prdata        <= 32'b0;
        end else begin
            // Clear init on the transition through ENDOP (operation finished)
            if (currentState == ENDOP) begin
                init <= 1'b0;
            end
            if (psel && penable && !init && state && !pready) begin
                pslverr <= 1'b0;
                if (pwrite) begin
                    received_data <= pwdata;
                    pready        <= 1'b1;
                    init          <= 1'b1;
                    if (pwdata[5:0] > 6'd15) begin
                        pslverr <= 1'b1;
                        $display("[%0t] [ALU_DUT] APB WRITE with INVALID address: pwdata[5:0]=%0d (>15) -> pslverr=1",
                                 $time, pwdata[5:0]);
                    end
                    $display("[%0t] [ALU_DUT] APB WRITE: pwdata=%b | opcode=%b shift=%b const=%b op2=%0d op1=%0d addr=%0d",
                             $time, pwdata, pwdata[31:28], pwdata[27:26], pwdata[25:22],
                             pwdata[21:14], pwdata[13:6], pwdata[5:0]);
                end else begin
                    case (paddr)
                        32'd0  : prdata <= ResultReg_0;
                        32'd1  : prdata <= ResultReg_1;
                        32'd2  : prdata <= ResultReg_2;
                        32'd3  : prdata <= ResultReg_3;
                        32'd4  : prdata <= ResultReg_4;
                        32'd5  : prdata <= ResultReg_5;
                        32'd6  : prdata <= ResultReg_6;
                        32'd7  : prdata <= ResultReg_7;
                        32'd8  : prdata <= ResultReg_8;
                        32'd9  : prdata <= ResultReg_9;
                        32'd10 : prdata <= ResultReg_10;
                        32'd11 : prdata <= ResultReg_11;
                        32'd12 : prdata <= ResultReg_12;
                        32'd13 : prdata <= ResultReg_13;
                        32'd14 : prdata <= ResultReg_14;
                        32'd15 : prdata <= ResultReg_15;
                        32'd16 : prdata <= received_data;
                        default: pslverr <= 1'b1;
                    endcase
                    if (paddr > 32'd16) begin
                        $display("[%0t] [ALU_DUT] APB READ with INVALID address: paddr=%0d (>16) -> pslverr=1",
                                 $time, paddr);
                    end else begin
                        $display("[%0t] [ALU_DUT] APB READ: paddr=%0d",
                                 $time, paddr);
                    end
                    pready <= 1'b1;
                end
            end else begin
                pready <= 1'b0;
            end
        end
    end

    // FSM next-state (combinational)
    always @(*) begin
        nextState = currentState;
        case (currentState)
            INIT: begin
                if (!reset_n)      nextState = INIT;
                else if (init)     nextState = SETUP;
            end
            SETUP: begin
                if (!reset_n)                                   nextState = INIT;
                else if (received_data[31:28] == 4'b0001)       nextState = ADD1;
                else if (received_data[31:28] == 4'b0010)       nextState = ADD2;
                else if (received_data[31:28] == 4'b0011)       nextState = ADD3;
                else if (received_data[31:28] == 4'b0100)       nextState = SHIFT_OP1;
                else if (received_data[31:28] == 4'b0101)       nextState = AND;
                else if (received_data[31:28] == 4'b0110)       nextState = OR;
                else if (received_data[31:28] == 4'b0111)       nextState = NAND;
                else if (received_data[31:28] == 4'b1000)       nextState = NOR;
                else if (received_data[31:28] == 4'b1001)       nextState = COMP;
                else                                            nextState = ENDOP;
            end
            ADD1     : nextState = (!reset_n) ? INIT : ENDOP;
            ADD2     : nextState = (!reset_n) ? INIT : ENDOP;
            ADD3     : nextState = (!reset_n) ? INIT : ENDOP;
            SHIFT_OP1: nextState = (!reset_n) ? INIT : ENDOP;
            AND      : nextState = (!reset_n) ? INIT : ENDOP;
            OR       : nextState = (!reset_n) ? INIT : ENDOP;
            NAND     : nextState = (!reset_n) ? INIT : ENDOP;
            NOR      : nextState = (!reset_n) ? INIT : ENDOP;
            COMP     : nextState = (!reset_n) ? INIT : ENDOP;
            ENDOP    : nextState = INIT;
            default  : nextState = INIT;
        endcase
    end

    // One-hot control signals derived from the current state (strictly
    // combinational). init and endop are NOT driven here.
    always @(*) begin
        load_op   = (currentState == SETUP)     ? 1'b1 : 1'b0;
        shift_op1 = (currentState == SHIFT_OP1) ? 1'b1 : 1'b0;
        add1      = (currentState == ADD1)      ? 1'b1 : 1'b0;
        add2      = (currentState == ADD2)      ? 1'b1 : 1'b0;
        add3      = (currentState == ADD3)      ? 1'b1 : 1'b0;
        and_op    = (currentState == AND)       ? 1'b1 : 1'b0;
        or_op     = (currentState == OR)        ? 1'b1 : 1'b0;
        nand_op   = (currentState == NAND)      ? 1'b1 : 1'b0;
        nor_op    = (currentState == NOR)       ? 1'b1 : 1'b0;
        comp      = (currentState == COMP)      ? 1'b1 : 1'b0;
    end

    // State register. init is driven by the APB block (set on pwrite) and
    // cleared above when the FSM transitions through ENDOP, so the two
    // drivers act on disjoint conditions.
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            currentState <= INIT;
        end else begin
            currentState <= nextState;
            if (currentState != nextState) begin
                $display("[%0t] [ALU_DUT] FSM: %s -> %s",
                         $time, fsm_state_name(currentState), fsm_state_name(nextState));
            end
        end
    end

    // Operand registers (load_op = 1 in the SETUP state)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            op1       <= 8'b0;
            op2       <= 8'b0;
            const_val <= 4'b0;
        end else if (load_op) begin
            op1       <= received_data[13:6];
            op2       <= received_data[21:14];
            const_val <= received_data[25:22];
            $display("[%0t] [ALU_DUT] LOAD_OP: op1=%0d op2=%0d const=%0d",
                     $time, received_data[13:6], received_data[21:14], received_data[25:22]);
        end
    end

    // Single sequential driver for result and endop.
    // All ALU operations are executed in one block so that the two signals
    // have exactly one driver.
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            result <= 9'b0;
            endop  <= 1'b0;
        end else begin
            if (currentState == INIT) begin
                endop <= 1'b0;
            end
            if (add1) begin
                result <= op1 + op2;
                endop  <= 1'b1;
                $display("[%0t] [ALU_DUT] OP ADD1: %0d + %0d = %0d",
                         $time, op1, op2, {1'b0, op1} + {1'b0, op2});
            end else if (add2) begin
                result <= op1 + {4'b0000, const_val};
                endop  <= 1'b1;
                $display("[%0t] [ALU_DUT] OP ADD2: %0d + const(%0d) = %0d",
                         $time, op1, const_val, {1'b0, op1} + {5'b00000, const_val});
            end else if (add3) begin
                result <= op2 + {4'b0000, const_val};
                endop  <= 1'b1;
                $display("[%0t] [ALU_DUT] OP ADD3: %0d + const(%0d) = %0d",
                         $time, op2, const_val, {1'b0, op2} + {5'b00000, const_val});
            end else if (shift_op1) begin
                result <= op1 << received_data[27:26];
                endop  <= 1'b1;
                $display("[%0t] [ALU_DUT] OP SHIFT_OP1: %0d << %0d = %0d (9-bit)",
                         $time, op1, received_data[27:26], ({1'b0, op1} << received_data[27:26]) & 9'h1FF);
            end else if (and_op) begin
                result <= op1 & op2;
                endop  <= 1'b1;
                $display("[%0t] [ALU_DUT] OP AND: %0d & %0d = %0d",
                         $time, op1, op2, op1 & op2);
            end else if (or_op) begin
                result <= op1 | op2;
                endop  <= 1'b1;
                $display("[%0t] [ALU_DUT] OP OR: %0d | %0d = %0d",
                         $time, op1, op2, op1 | op2);
            end else if (nor_op) begin
                result <= ~(op1 | op2);
                endop  <= 1'b1;
                $display("[%0t] [ALU_DUT] OP NOR: ~(%0d | %0d) = %0d",
                         $time, op1, op2, ~({1'b0, op1} | {1'b0, op2}));
            end else if (nand_op) begin
                result <= ~(op1 & op2);
                endop  <= 1'b1;
                $display("[%0t] [ALU_DUT] OP NAND: ~(%0d & %0d) = %0d",
                         $time, op1, op2, ~({1'b0, op1} & {1'b0, op2}));
            end else if (comp) begin
                if (op1 > op2) begin
                    result <= 9'd1;
                    $display("[%0t] [ALU_DUT] OP COMP: %0d > %0d -> result=1",
                             $time, op1, op2);
                end else if (op1 < op2) begin
                    result <= 9'd2;
                    $display("[%0t] [ALU_DUT] OP COMP: %0d < %0d -> result=2",
                             $time, op1, op2);
                end else begin
                    result <= 9'b100000000;
                    $display("[%0t] [ALU_DUT] OP COMP: %0d == %0d -> result=256 (bit 8)",
                             $time, op1, op2);
                end
                endop <= 1'b1;
            end
        end
    end

    // Destination address used when storing the result into a ResultReg_*
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            result_address <= 6'b0;
        else
            result_address <= received_data[5:0];
    end

    // Result registers (16 registers of 9 bits each).
    // pslverr is NOT driven here (it is driven by the APB block).
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ResultReg_0  <= 9'b0;
            ResultReg_1  <= 9'b0;
            ResultReg_2  <= 9'b0;
            ResultReg_3  <= 9'b0;
            ResultReg_4  <= 9'b0;
            ResultReg_5  <= 9'b0;
            ResultReg_6  <= 9'b0;
            ResultReg_7  <= 9'b0;
            ResultReg_8  <= 9'b0;
            ResultReg_9  <= 9'b0;
            ResultReg_10 <= 9'b0;
            ResultReg_11 <= 9'b0;
            ResultReg_12 <= 9'b0;
            ResultReg_13 <= 9'b0;
            ResultReg_14 <= 9'b0;
            ResultReg_15 <= 9'b0;
        end else if (currentState == ENDOP && endop) begin
            case (result_address)
                6'd0  : begin ResultReg_0  <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_0  <= %0d", $time, result); end
                6'd1  : begin ResultReg_1  <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_1  <= %0d", $time, result); end
                6'd2  : begin ResultReg_2  <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_2  <= %0d", $time, result); end
                6'd3  : begin ResultReg_3  <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_3  <= %0d", $time, result); end
                6'd4  : begin ResultReg_4  <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_4  <= %0d", $time, result); end
                6'd5  : begin ResultReg_5  <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_5  <= %0d", $time, result); end
                6'd6  : begin ResultReg_6  <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_6  <= %0d", $time, result); end
                6'd7  : begin ResultReg_7  <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_7  <= %0d", $time, result); end
                6'd8  : begin ResultReg_8  <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_8  <= %0d", $time, result); end
                6'd9  : begin ResultReg_9  <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_9  <= %0d", $time, result); end
                6'd10 : begin ResultReg_10 <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_10 <= %0d", $time, result); end
                6'd11 : begin ResultReg_11 <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_11 <= %0d", $time, result); end
                6'd12 : begin ResultReg_12 <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_12 <= %0d", $time, result); end
                6'd13 : begin ResultReg_13 <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_13 <= %0d", $time, result); end
                6'd14 : begin ResultReg_14 <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_14 <= %0d", $time, result); end
                6'd15 : begin ResultReg_15 <= result; $display("[%0t] [ALU_DUT] STORE ResultReg_15 <= %0d", $time, result); end
                default: begin
                    $display("[%0t] [ALU_DUT] STORE with INVALID address: result_address=%0d",
                             $time, result_address);
                end
            endcase
        end
    end

    // FSM state-name helper used by the $display messages above
    function [8*9-1:0] fsm_state_name;
        input [4:0] s;
        begin
            case (s)
                INIT     : fsm_state_name = "INIT     ";
                SETUP    : fsm_state_name = "SETUP    ";
                ADD1     : fsm_state_name = "ADD1     ";
                ADD2     : fsm_state_name = "ADD2     ";
                ADD3     : fsm_state_name = "ADD3     ";
                SHIFT_OP1: fsm_state_name = "SHIFT_OP1";
                AND      : fsm_state_name = "AND      ";
                OR       : fsm_state_name = "OR       ";
                NAND     : fsm_state_name = "NAND     ";
                NOR      : fsm_state_name = "NOR      ";
                COMP     : fsm_state_name = "COMP     ";
                ENDOP    : fsm_state_name = "ENDOP    ";
                default  : fsm_state_name = "UNKNOWN  ";
            endcase
        end
    endfunction

endmodule

`include "environment.sv"

program test_initial_t1(apb_interface apb_interface_instance, output_interface output_interface_instance, irq_interface irq_interface_instance);

  environment env;

  initial begin
    env = new(output_interface_instance, apb_interface_instance, irq_interface_instance);

    // Total transactions across all tests
    env.gen.repeat_count = 103;

    // TEST 1: Postfix expression 5 1 2 + 4 * + 3 - = 14
    //   Step: push 5,1,2 -> ADD(1+2=3) -> push 4 -> MUL(3*4=12)
    //         -> ADD(5+12=17) -> push 3 -> SUB(17-3=14)
    $display("");
    $display("T=%0t [TEST1] ========================================", $time);
    $display("T=%0t [TEST1] Postfix: 5 1 2 + 4 * + 3 -", $time);
    $display("T=%0t [TEST1] Expected result: 14 (0x0E)", $time);
    $display("T=%0t [TEST1] ========================================", $time);

    env.gen.generate_write(32'h01, 5'h0C);  // DIVIDER = 1
    env.gen.generate_write(32'h01, 5'h10);  // CONTROL: CLEAR_FIFO
    env.gen.generate_write(32'h05, 5'h00);  // DATA = 5
    env.gen.generate_write(32'h01, 5'h00);  // DATA = 1
    env.gen.generate_write(32'h02, 5'h00);  // DATA = 2
    env.gen.generate_write(32'h01, 5'h04);  // OP = ADD (bit 0)
    env.gen.generate_write(32'h04, 5'h00);  // DATA = 4
    env.gen.generate_write(32'h04, 5'h04);  // OP = MUL (bit 2)
    env.gen.generate_write(32'h01, 5'h04);  // OP = ADD (bit 0)
    env.gen.generate_write(32'h03, 5'h00);  // DATA = 3
    env.gen.generate_write(32'h02, 5'h04);  // OP = SUB (bit 1)
    env.gen.generate_write(32'h04, 5'h10);  // CONTROL: START
    env.gen.generate_read(5'h08);           // Read STATUS
    env.gen.generate_read(5'h08);           // Read STATUS

    // TEST 2: Division  20 4 / = 5
    $display("");
    $display("T=%0t [TEST2] ========================================", $time);
    $display("T=%0t [TEST2] Postfix: 20 4 /", $time);
    $display("T=%0t [TEST2] Expected result: 5", $time);
    $display("T=%0t [TEST2] ========================================", $time);

    env.gen.generate_write(32'h03, 5'h10);  // CONTROL: CLEAR_FIFO + CLEAR_IRQ
    env.gen.generate_write(32'h14, 5'h00);  // DATA = 20
    env.gen.generate_write(32'h04, 5'h00);  // DATA = 4
    env.gen.generate_write(32'h08, 5'h04);  // OP = DIV (bit 3)
    env.gen.generate_write(32'h04, 5'h10);  // CONTROL: START
    env.gen.generate_read(5'h08);           // Read STATUS

    // TEST 3: Modulo  17 5 % = 2
    $display("");
    $display("T=%0t [TEST3] ========================================", $time);
    $display("T=%0t [TEST3] Postfix: 17 5 %%", $time);
    $display("T=%0t [TEST3] Expected result: 2", $time);
    $display("T=%0t [TEST3] ========================================", $time);

    env.gen.generate_write(32'h03, 5'h10);  // CONTROL: CLEAR_FIFO + CLEAR_IRQ
    env.gen.generate_write(32'h11, 5'h00);  // DATA = 17
    env.gen.generate_write(32'h05, 5'h00);  // DATA = 5
    env.gen.generate_write(32'h10, 5'h04);  // OP = MOD (bit 4)
    env.gen.generate_write(32'h04, 5'h10);  // CONTROL: START
    env.gen.generate_read(5'h08);           // Read STATUS

    // TEST 4: Shift Left  1 3 << = 8
    $display("");
    $display("T=%0t [TEST4] ========================================", $time);
    $display("T=%0t [TEST4] Postfix: 1 3 <<", $time);
    $display("T=%0t [TEST4] Expected result: 8", $time);
    $display("T=%0t [TEST4] ========================================", $time);

    env.gen.generate_write(32'h03, 5'h10);  // CONTROL: CLEAR_FIFO + CLEAR_IRQ
    env.gen.generate_write(32'h01, 5'h00);  // DATA = 1
    env.gen.generate_write(32'h03, 5'h00);  // DATA = 3
    env.gen.generate_write(32'h20, 5'h04);  // OP = SHL (bit 5)
    env.gen.generate_write(32'h04, 5'h10);  // CONTROL: START
    env.gen.generate_read(5'h08);           // Read STATUS

    // TEST 5: Shift Right  16 2 >> = 4
    $display("");
    $display("T=%0t [TEST5] ========================================", $time);
    $display("T=%0t [TEST5] Postfix: 16 2 >>", $time);
    $display("T=%0t [TEST5] Expected result: 4", $time);
    $display("T=%0t [TEST5] ========================================", $time);

    env.gen.generate_write(32'h03, 5'h10);  // CONTROL: CLEAR_FIFO + CLEAR_IRQ
    env.gen.generate_write(32'h10, 5'h00);  // DATA = 16
    env.gen.generate_write(32'h02, 5'h00);  // DATA = 2
    env.gen.generate_write(32'h40, 5'h04);  // OP = SHR (bit 6)
    env.gen.generate_write(32'h04, 5'h10);  // CONTROL: START
    env.gen.generate_read(5'h08);           // Read STATUS

    // TEST 6: IRQ - Enable DONE mask, run 10 + 5 = 15, check IRQ
    $display("");
    $display("T=%0t [TEST6] ========================================", $time);
    $display("T=%0t [TEST6] IRQ test: MASK DONE, 10 5 +", $time);
    $display("T=%0t [TEST6] Expected result: 15, IRQ should fire", $time);
    $display("T=%0t [TEST6] ========================================", $time);

    env.gen.generate_write(32'h01, 5'h14);  // MASK = 0x01 (DONE_MASK)
    env.gen.generate_write(32'h03, 5'h10);  // CONTROL: CLEAR_FIFO + CLEAR_IRQ
    env.gen.generate_write(32'h0A, 5'h00);  // DATA = 10
    env.gen.generate_write(32'h05, 5'h00);  // DATA = 5
    env.gen.generate_write(32'h01, 5'h04);  // OP = ADD (bit 0)
    env.gen.generate_write(32'h04, 5'h10);  // CONTROL: START
    env.gen.generate_read(5'h08);           // Read STATUS (should show DONE)

    // TEST 7: Overflow  200*200 + 200*200 = 80000 > 65535
    $display("");
    $display("T=%0t [TEST7] ========================================", $time);
    $display("T=%0t [TEST7] Overflow: 200 200 * 200 200 * +", $time);
    $display("T=%0t [TEST7] 40000 + 40000 = 80000 > 65535", $time);
    $display("T=%0t [TEST7] ========================================", $time);

    env.gen.generate_write(32'h00, 5'h14);  // MASK = 0x00 (clear mask)
    env.gen.generate_write(32'h03, 5'h10);  // CONTROL: CLEAR_FIFO + CLEAR_IRQ
    env.gen.generate_write(32'hC8, 5'h00);  // DATA = 200
    env.gen.generate_write(32'hC8, 5'h00);  // DATA = 200
    env.gen.generate_write(32'h04, 5'h04);  // OP = MUL (bit 2)
    env.gen.generate_write(32'hC8, 5'h00);  // DATA = 200
    env.gen.generate_write(32'hC8, 5'h00);  // DATA = 200
    env.gen.generate_write(32'h04, 5'h04);  // OP = MUL (bit 2)
    env.gen.generate_write(32'h01, 5'h04);  // OP = ADD (bit 0)
    env.gen.generate_write(32'h04, 5'h10);  // CONTROL: START
    env.gen.generate_read(5'h08);           // Read STATUS (should show OVERFLOW)

    // TEST 8: Division by zero  5 0 / -> FAIL
    $display("");
    $display("T=%0t [TEST8] ========================================", $time);
    $display("T=%0t [TEST8] Div by zero: 5 0 /", $time);
    $display("T=%0t [TEST8] Expected: FAIL", $time);
    $display("T=%0t [TEST8] ========================================", $time);

    env.gen.generate_write(32'h03, 5'h10);  // CONTROL: CLEAR_FIFO + CLEAR_IRQ
    env.gen.generate_write(32'h05, 5'h00);  // DATA = 5
    env.gen.generate_write(32'h00, 5'h00);  // DATA = 0
    env.gen.generate_write(32'h08, 5'h04);  // OP = DIV (bit 3)
    env.gen.generate_write(32'h04, 5'h10);  // CONTROL: START
    env.gen.generate_read(5'h08);           // Read STATUS (should show FAIL)

    // TEST 9: pslverr - invalid addresses
    $display("");
    $display("T=%0t [TEST9] ========================================", $time);
    $display("T=%0t [TEST9] pslverr: read addr 0x1C (>0x18)", $time);
    $display("T=%0t [TEST9] pslverr: read addr 0x01 (unaligned)", $time);
    $display("T=%0t [TEST9] ========================================", $time);

    env.gen.generate_read(5'h1C);           // Invalid: > 0x18
    env.gen.generate_read(5'h01);           // Invalid: unaligned

    // TEST 10: CONFIG register - ignore MUL, try 3 * 4 -> FAIL
    $display("");
    $display("T=%0t [TEST10] ========================================", $time);
    $display("T=%0t [TEST10] CONFIG=0x04 (IGNORE_MUL), try 3 4 *", $time);
    $display("T=%0t [TEST10] Expected: FAIL (MUL blocked by CONFIG)", $time);
    $display("T=%0t [TEST10] ========================================", $time);

    env.gen.generate_write(32'h03, 5'h10);  // CONTROL: CLEAR_FIFO + CLEAR_IRQ
    env.gen.generate_write(32'h04, 5'h18);  // CONFIG = 0x04 (IGNORE_MUL)
    env.gen.generate_write(32'h03, 5'h00);  // DATA = 3
    env.gen.generate_write(32'h04, 5'h00);  // DATA = 4
    env.gen.generate_write(32'h04, 5'h04);  // OP = MUL (bit 2)
    env.gen.generate_write(32'h04, 5'h10);  // CONTROL: START
    env.gen.generate_read(5'h08);           // Read STATUS (should show FAIL)
    env.gen.generate_write(32'h00, 5'h18);  // CONFIG = 0x00 (clear ignore flags)

    // TEST 11: Register coverage — read/write all valid registers
    $display("");
    $display("T=%0t [TEST11] ========================================", $time);
    $display("T=%0t [TEST11] Register coverage sweep", $time);
    $display("T=%0t [TEST11] ========================================", $time);

    env.gen.generate_read(5'h00);           // Read DATA
    env.gen.generate_read(5'h04);           // Read OPS
    env.gen.generate_read(5'h0C);           // Read DIVIDER
    env.gen.generate_read(5'h10);           // Read CONTROL
    env.gen.generate_read(5'h14);           // Read MASK
    env.gen.generate_read(5'h18);           // Read CONFIG
    env.gen.generate_write(32'h02, 5'h0C);  // Write DIVIDER = 2

    // TEST 12: Result=0  ->  5 5 - = 0  (hits result_coverage zero bin)
    $display("");
    $display("T=%0t [TEST12] ========================================", $time);
    $display("T=%0t [TEST12] Postfix: 5 5 -", $time);
    $display("T=%0t [TEST12] Expected result: 0", $time);
    $display("T=%0t [TEST12] ========================================", $time);

    env.gen.generate_write(32'h03, 5'h10);  // CONTROL: CLEAR_FIFO + CLEAR_IRQ
    env.gen.generate_write(32'h05, 5'h00);  // DATA = 5
    env.gen.generate_write(32'h05, 5'h00);  // DATA = 5
    env.gen.generate_write(32'h02, 5'h04);  // OP = SUB (bit 1)
    env.gen.generate_write(32'h04, 5'h10);  // CONTROL: START
    env.gen.generate_read(5'h08);           // Read STATUS

    // TEST 13: Result=200  ->  100 100 + = 200  (hits result mid bin)
    $display("");
    $display("T=%0t [TEST13] ========================================", $time);
    $display("T=%0t [TEST13] Postfix: 100 100 +", $time);
    $display("T=%0t [TEST13] Expected result: 200", $time);
    $display("T=%0t [TEST13] ========================================", $time);

    env.gen.generate_write(32'h03, 5'h10);  // CONTROL: CLEAR_FIFO + CLEAR_IRQ
    env.gen.generate_write(32'h64, 5'h00);  // DATA = 100
    env.gen.generate_write(32'h64, 5'h00);  // DATA = 100
    env.gen.generate_write(32'h01, 5'h04);  // OP = ADD (bit 0)
    env.gen.generate_write(32'h04, 5'h10);  // CONTROL: START
    env.gen.generate_read(5'h08);           // Read STATUS

    // TEST 14: Result=10000  ->  100 100 * = 10000  (hits result hi bin)
    $display("");
    $display("T=%0t [TEST14] ========================================", $time);
    $display("T=%0t [TEST14] Postfix: 100 100 *", $time);
    $display("T=%0t [TEST14] Expected result: 10000", $time);
    $display("T=%0t [TEST14] ========================================", $time);

    env.gen.generate_write(32'h03, 5'h10);  // CONTROL: CLEAR_FIFO + CLEAR_IRQ
    env.gen.generate_write(32'h64, 5'h00);  // DATA = 100
    env.gen.generate_write(32'h64, 5'h00);  // DATA = 100
    env.gen.generate_write(32'h04, 5'h04);  // OP = MUL (bit 2)
    env.gen.generate_write(32'h04, 5'h10);  // CONTROL: START
    env.gen.generate_read(5'h08);           // Read STATUS

    // TEST 15: Write data coverage — hit hi and very_large bins
    $display("");
    $display("T=%0t [TEST15] ========================================", $time);
    $display("T=%0t [TEST15] Write data coverage: 1000, 70000", $time);
    $display("T=%0t [TEST15] ========================================", $time);

    env.gen.generate_write(32'h03, 5'h10);    // CONTROL: CLEAR_FIFO + CLEAR_IRQ
    env.gen.generate_write(32'h03E8, 5'h00);  // DATA = 1000 (hits write_data hi bin)
    env.gen.generate_write(32'h11170, 5'h00); // DATA = 70000 (hits write_data very_large bin)
    env.gen.generate_write(32'h02, 5'h04);    // OP = SUB
    env.gen.generate_write(32'h04, 5'h10);    // CONTROL: START
    env.gen.generate_read(5'h08);             // Read STATUS

    env.run();
  end
endprogram

// Register bit-toggle test.
// Writes randomized values to every register, then writes the alternating
// patterns 0x55 (0101_0101) and 0xAA (1010_1010) to verify that every bit
// can toggle both 0->1 and 1->0.
`include "environment.sv"

program test(apb_interface apb_intf, door_interface door_intf, led_interface led_intf);

  environment env;

  initial begin
    env = new(apb_intf, door_intf, led_intf);

    $display("%0t [TEST-REG] Starting register toggle test", $time());

    // Initial read-back of each register to establish a known state.
    env.apb_gen.read_reg_transaction(0);
    env.apb_gen.read_reg_transaction(1);
    env.apb_gen.read_reg_transaction(2);

    // Randomized writes followed by read-back on each register.
    env.apb_gen.write_reg_transaction(0, $random());
    env.apb_gen.read_reg_transaction(0);
    env.apb_gen.write_reg_transaction(1, $random());
    env.apb_gen.read_reg_transaction(1);
    env.apb_gen.write_reg_transaction(2, $random());
    env.apb_gen.read_reg_transaction(2);

    // Pattern 0x55 (0101_0101) — toggles every odd-indexed bit to 1.
    env.apb_gen.write_reg_transaction(0, 8'b01010101);
    env.apb_gen.read_reg_transaction(0);
    env.apb_gen.write_reg_transaction(1, 8'b01010101);
    env.apb_gen.read_reg_transaction(1);
    env.apb_gen.write_reg_transaction(2, 8'b01010101);
    env.apb_gen.read_reg_transaction(2);

    // Pattern 0xAA (1010_1010) — toggles every even-indexed bit to 1.
    env.apb_gen.write_reg_transaction(0, 8'b10101010);
    env.apb_gen.read_reg_transaction(0);
    env.apb_gen.write_reg_transaction(1, 8'b10101010);
    env.apb_gen.read_reg_transaction(1);
    env.apb_gen.write_reg_transaction(2, 8'b10101010);
    env.apb_gen.read_reg_transaction(2);

    // Run the environment.
    env.run();
  end
endprogram

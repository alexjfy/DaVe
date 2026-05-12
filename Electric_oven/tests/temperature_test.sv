// Temperature register test.
// Programs PIZZA mode with a short timer, then cycles through several
// temperature values (200, 150, 50 degrees) to exercise temp_set_reg.
`include "environment.sv"

program test(apb_interface apb_intf, door_interface door_intf, led_interface led_intf);

  environment env;

  initial begin
    env = new(apb_intf, door_intf, led_intf);

    $display("%0t [TEST-TEMP] Starting temperature register test", $time());

    env.apb_gen.write_reg_transaction(1, 'b011);     // PIZZA mode
    env.apb_gen.write_reg_transaction(2, 10);        // Timer = 10
    env.apb_gen.read_reg_transaction(2);              // Read-back timer
    env.apb_gen.write_reg_transaction(1, 'b1010);    // HEAT mode + start bit
    env.apb_gen.read_reg_transaction(1);              // Read-back mode register

    env.apb_gen.write_reg_transaction(0, 4);         // Temperature = 200 degrees
    env.apb_gen.read_reg_transaction(0);              // Read-back temperature

    env.apb_gen.write_reg_transaction(0, 3);         // Temperature = 150 degrees
    env.apb_gen.read_reg_transaction(0);              // Read-back temperature

    // Program 50 degrees twice to confirm idempotent writes are accepted.
    repeat(2)
      env.apb_gen.write_reg_transaction(0, 1);       // Temperature = 50 degrees
    env.apb_gen.read_reg_transaction(0);              // Read-back temperature

    // Run the environment.
    env.run();
  end
endprogram

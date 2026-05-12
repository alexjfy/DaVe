// Combined timer + operating mode + temperature test.
// Programs all three registers together to exercise the full ready-LED
// assertion scenario (mode active, temperature > 0, timeout asserted,
// door closed).
`include "environment.sv"

program test(apb_interface apb_intf, door_interface door_intf, led_interface led_intf);

  environment env;

  initial begin
    env = new(apb_intf, door_intf, led_intf);

    $display("%0t [TEST-TIMEMOD] Starting combined timer+mode+temperature test", $time());

    env.apb_gen.write_reg_transaction(1, 'b011);     // PIZZA mode
    env.apb_gen.write_reg_transaction(2, 50);        // Program timer with 50
    env.apb_gen.read_reg_transaction(2);              // Read-back timer value
    env.apb_gen.write_reg_transaction(1, 'b1011);    // PIZZA mode + start bit
    env.apb_gen.read_reg_transaction(1);              // Read-back mode register
    env.apb_gen.write_reg_transaction(0, 3);         // Temperature = 150 degrees
    env.apb_gen.read_reg_transaction(0);              // Read-back temperature

    // Run the environment.
    env.run();
  end
endprogram

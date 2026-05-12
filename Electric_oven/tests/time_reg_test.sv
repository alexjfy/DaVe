// Timer register test.
// Verifies programming and read-back of timer_reg using a representative
// timer value, then writes the start command to operation_mod_reg.
`include "environment.sv"

program test(apb_interface apb_intf, door_interface door_intf, led_interface led_intf);

  environment env;

  initial begin
    env = new(apb_intf, door_intf, led_intf);

    $display("%0t [TEST-TIMEREG] Starting timer register test", $time());

    env.apb_gen.write_reg_transaction(1, 'b011);     // Activate PIZZA mode
    env.apb_gen.write_reg_transaction(2, 125);       // Program timer with 125
    env.apb_gen.read_reg_transaction(2);              // Read-back timer value
    env.apb_gen.write_reg_transaction(1, 'b1010);    // HEAT mode + start bit
    env.apb_gen.read_reg_transaction(1);              // Read-back mode register

    // Run the environment.
    env.run();
  end
endprogram

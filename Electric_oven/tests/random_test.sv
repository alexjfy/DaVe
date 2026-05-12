// Directed smoke test.
// Writes two temperature values (50 degrees, 150 degrees) and then selects
// PIZZA mode through the operation_mod_reg register.
`include "environment.sv"

program test(apb_interface apb_intf, door_interface door_intf, led_interface led_intf);

  // Environment instance shared by every test in this project.
  environment env;

  initial begin
    // Create the verification environment with all three interfaces.
    env = new(apb_intf, door_intf, led_intf);

    $display("%0t [TEST-RANDOM] Starting directed smoke test", $time());

    // Directed APB writes exercising the temperature register then the mode register.
    env.apb_gen.write_reg_transaction(0, 1);       // Set 50 degrees  (temp_set_reg)
    env.apb_gen.write_reg_transaction(0, 3);       // Set 150 degrees (temp_set_reg)
    env.apb_gen.write_reg_transaction(1, 'b011);   // Select PIZZA mode (operation_mod_reg)

    // Run the environment — launches generators, drivers, monitors, scoreboard.
    env.run();
  end
endprogram

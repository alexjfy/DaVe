// Coverage-targeted test that also exercises a full functional sequence.
// First drives timer_reg with values spread across every data_cp bin, then
// walks through each of the four operating modes (COOK, HEAT, PIZZA, DEFROST)
// with a timer and temperature programmed in.
`include "environment.sv"

program test(apb_interface apb_intf, door_interface door_intf, led_interface led_intf);

  environment env;

  initial begin
    env = new(apb_intf, door_intf, led_intf);

    $display("%0t [TEST-OPMOD] Starting coverage-targeted test", $time());

    // Coverage-targeted transactions on timer_reg (addr 0x02).
    // timer_reg is safe for arbitrary writes — the countdown only starts when bit 3
    // of operation_mod_reg is written with 1.
    //   range[0] = [0:63]    - hit below with value 0 (also covers lowest_value)
    //   range[1] = [64:127]  - hit with value 100
    //   range[2] = [128:191] - hit with value 150
    //   range[3] = [192:255] - hit with value 200 and again with 255 (also highest_value)
    env.apb_gen.write_reg_transaction(2, 8'd0);     // hits lowest_value {0}
    env.apb_gen.read_reg_transaction(2);             // read back 0
    env.apb_gen.write_reg_transaction(2, 8'd100);    // hits range[1]
    env.apb_gen.write_reg_transaction(2, 8'd150);    // hits range[2]
    env.apb_gen.write_reg_transaction(2, 8'd200);    // hits range[3]
    env.apb_gen.write_reg_transaction(2, 8'd255);    // hits highest_value {255}
    env.apb_gen.read_reg_transaction(2);             // read back 255

    // Functional sequence exercising each mode with a timer and temperature set.
    env.apb_gen.write_reg_transaction(1, 'b011);     // PIZZA mode
    env.apb_gen.write_reg_transaction(2, 50);        // Timer = 50
    env.apb_gen.read_reg_transaction(2);             // Read-back timer
    env.apb_gen.write_reg_transaction(1, 'b1011);    // PIZZA mode + start bit
    env.apb_gen.read_reg_transaction(1);             // Read-back mode register
    env.apb_gen.write_reg_transaction(0, 3);         // Temperature = 150 degrees
    env.apb_gen.read_reg_transaction(0);             // Read-back temperature
    env.apb_gen.write_reg_transaction(1, 'b1100);    // DEFROST mode + start bit
    env.apb_gen.read_reg_transaction(1);             // Read-back mode register
    env.apb_gen.write_reg_transaction(1, 'b1001);    // COOK mode + start bit
    env.apb_gen.read_reg_transaction(1);             // Read-back mode register
    env.apb_gen.write_reg_transaction(1, 'b1010);    // HEAT mode + start bit
    env.apb_gen.read_reg_transaction(1);             // Read-back mode register

    // Run the environment.
    env.run();
  end
endprogram

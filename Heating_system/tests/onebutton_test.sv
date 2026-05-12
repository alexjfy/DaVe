//-------------------------------------------------------------------------
//                        onebutton_test.sv
//-------------------------------------------------------------------------
`include "environment.sv"
program test(apb_interface apb_vif, output_interface out_vif, buttons_interface buttons_vif);

  environment env;

  initial begin
    env = new(apb_vif, out_vif, buttons_vif);

    env.buttons_gen.repeat_count = 4;

    // disable randomization on button_child_prot and force it to 0
    // otherwise the buttons can't trigger transitions
    env.buttons_gen.trans.button_child_prot.rand_mode(0);
    env.buttons_gen.trans.button_child_prot = 0;

    //start env in background so the drivers catch the reset
    fork
      env.run();
    join_none

    //wait for reset to deassert
    @(negedge apb_vif.reset);
    repeat(5) @(posedge apb_vif.clk);

    // write func_reg = 0x07: bit0 econ, bit1 comf, bit2 thermo
    $display("[TEST] func_reg = 0x07");
    env.apb_gen.write_reg(0, 8'b00000111);

    repeat(5) @(posedge apb_vif.clk);

    //read it back to check
    env.apb_gen.read_reg(0);

    //env.run() calls $finish on its own when done
    wait(0);
  end
endprogram
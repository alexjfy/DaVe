//-------------------------------------------------------------------------
//                        random_test.sv
//-------------------------------------------------------------------------
`include "environment.sv"
program test(apb_interface apb_vif, output_interface out_vif, buttons_interface buttons_vif);

  environment env;

  initial begin
    env = new(apb_vif, out_vif, buttons_vif);

    env.buttons_gen.repeat_count = 4;

    fork
      env.run();
    join_none

    @(negedge apb_vif.reset);
    repeat(5) @(posedge apb_vif.clk);

    // enable all modes
    env.apb_gen.write_reg(0, 8'b00000111);
    repeat(5) @(posedge apb_vif.clk);
    env.apb_gen.read_reg(0);

    wait(0);
  end
endprogram
//-------------------------------------------------------------------------
//                        all_modes_test.sv
//-------------------------------------------------------------------------
// directed test for all modes + child protection + func_reg enable/disable
// plus some extra writes at the end for APB coverage
`include "environment.sv"
program test(apb_interface apb_vif, output_interface out_vif, buttons_interface buttons_vif);

  environment env;

  // helper so we don't write the same thing 10 times
  task automatic inject_button(
    input bit econ, input bit comf, input bit thermo,
    input bit child_prot, input int hold_cycles, input int delay_cycles
  );
    buttons_transaction t;
    t = new();
    t.button_mod_econ = econ;
    t.button_mod_comf = comf;
    t.button_mod_thermo = thermo;
    t.button_child_prot = child_prot;
    t.delay = delay_cycles;
    t.hold = hold_cycles;
    env.buttons_gen2driv.put(t);
    // wait for delay + hold + a bit of margin
    repeat(delay_cycles + hold_cycles + 5) @(posedge apb_vif.clk);
  endtask

  initial begin
    env = new(apb_vif, out_vif, buttons_vif);
    env.buttons_gen.repeat_count = 0; // no random generation

    //reset
    fork
      env.pre_test();
    join

    //start drivers and monitors in background
    fork
      env.apb_driv.main();
      env.apb_mon.main();
      env.out_mon.main();
      env.buttons_driv.main();
      env.buttons_mon.main();
    join_none

    repeat(3) @(posedge apb_vif.clk);

    // setup: write func_reg = 0x07 to enable all modes
    $display("[TEST] setup: func_reg = 0x07");
    env.apb_gen.write_reg(0, 8'b00000111);
    repeat(5) @(posedge apb_vif.clk);
    env.apb_gen.read_reg(0);
    repeat(5) @(posedge apb_vif.clk);

    // test 1 - econ
    $display("[TEST] econ mode, hold=12");
    inject_button(1, 0, 0, 0, 12, 3);

    // test 2 - comf
    $display("[TEST] comf mode, hold=12");
    inject_button(0, 1, 0, 0, 12, 3);

    // test 3 - thermo
    $display("[TEST] thermo, hold=10");
    inject_button(0, 0, 1, 0, 10, 3);

    //now with child protection on - shouldn't transition to any mode
    $display("[TEST] econ with child_prot, should not work");
    inject_button(1, 0, 0, 1, 10, 3);

    $display("[TEST] comf with child_prot");
    inject_button(0, 1, 0, 1, 10, 3);

    $display("[TEST] thermo with child_prot");
    inject_button(0, 0, 1, 1, 10, 3);

    // disable econ in func_reg and press econ - shouldn't work
    $display("[TEST] func_reg=0x06, econ disabled");
    env.apb_gen.write_reg(0, 8'b00000110);
    repeat(5) @(posedge apb_vif.clk);
    inject_button(1, 0, 0, 0, 10, 3);

    //comf should still work
    $display("[TEST] comf with reg=0x06");
    inject_button(0, 1, 0, 0, 12, 3);

    // only thermo enabled
    $display("[TEST] reg=0x04, only thermo");
    env.apb_gen.write_reg(0, 8'b00000100);
    repeat(5) @(posedge apb_vif.clk);
    inject_button(0, 1, 0, 0, 10, 3); // comf - won't work
    inject_button(0, 0, 1, 0, 10, 3); // thermo - works

    // re-enable all, test econ->comf transition
    $display("[TEST] econ->comf transition");
    env.apb_gen.write_reg(0, 8'b00000111);
    repeat(5) @(posedge apb_vif.clk);
    inject_button(1, 0, 0, 0, 3, 3);
    inject_button(0, 1, 0, 0, 12, 1);

    // APB coverage boost: write/read all addresses to hit paddr and data bins
    $display("[TEST] APB coverage sweep");

    // all 4 addresses (ADDR_WIDTH=2)
    env.apb_gen.write_reg(0, 8'h00);  // lowest_value bin
    repeat(3) @(posedge apb_vif.clk);
    env.apb_gen.read_reg(0);
    repeat(3) @(posedge apb_vif.clk);

    env.apb_gen.write_reg(1, 8'h3F);
    repeat(3) @(posedge apb_vif.clk);
    env.apb_gen.read_reg(1);
    repeat(3) @(posedge apb_vif.clk);

    env.apb_gen.write_reg(2, 8'h80);
    repeat(3) @(posedge apb_vif.clk);
    env.apb_gen.read_reg(2);
    repeat(3) @(posedge apb_vif.clk);

    env.apb_gen.write_reg(3, 8'hC0);
    repeat(3) @(posedge apb_vif.clk);
    env.apb_gen.read_reg(3);
    repeat(3) @(posedge apb_vif.clk);

    // still missing a couple of data bins
    env.apb_gen.write_reg(0, 8'hFF);  // highest_value
    repeat(3) @(posedge apb_vif.clk);
    env.apb_gen.write_reg(0, 8'h50);  // range[1]
    repeat(3) @(posedge apb_vif.clk);

    // back to functional config
    env.apb_gen.write_reg(0, 8'h07);
    repeat(3) @(posedge apb_vif.clk);
    env.apb_gen.read_reg(0);
    repeat(5) @(posedge apb_vif.clk);

    //final coverage report
    $display("\n[TEST] ---- coverage ----");
    $display("[TEST] APB:");
    env.apb_mon.apb_coverage_colector.print_coverage();
    $display("[TEST] Output:");
    env.out_mon.output_coverage_colector.print_coverage();
    $display("[TEST] Buttons:");
    env.buttons_mon.buttons_coverage_colector.print_coverage();

    $display("[TEST] done");
    #100;
    $finish;
  end
endprogram

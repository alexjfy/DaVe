`include "environment.sv"

program test3(apb_interface apb_if, out_interface out_if);

  environment env;

  initial begin
    //creating environment
    env = new(apb_if, out_if);

    //setting the repeat count of generator as 4, means to generate 4 packets
    //env.gen.repeat_count = 10;

     env.gen.write_register_random('h11);
    env.gen.write_all_priority_reg();
    env.gen.write_register_random('h09);

    env.gen.read_register('h01);
    env.gen.read_register('h02);
    env.gen.read_register('h03);
    env.gen.read_register('h04);
    env.gen.read_register('h05);
    env.gen.read_register('h06);
    env.gen.read_register('h07);
    env.gen.read_register('h08);
    env.gen.read_register('h09);
    env.gen.read_register('h11);

     env.gen.write_register('h01, 'h55%8+1);
     env.gen.write_register('h02, 'h55%8+1);
     env.gen.write_register('h03, 'h55%8+1);
     env.gen.write_register('h04, 'h55%8+1);
     env.gen.write_register('h05, 'h55%8+1);
     env.gen.write_register('h06, 'h55%8+1);
     env.gen.write_register('h07, 'h55%8+1);
     env.gen.write_register('h08, 'h55%8+1);
     env.gen.write_register('h09, 'h55);
     env.gen.write_register('h11, 'h55);

    env.gen.read_register('h01);
    env.gen.read_register('h02);
    env.gen.read_register('h03);
    env.gen.read_register('h04);
    env.gen.read_register('h05);
    env.gen.read_register('h06);
    env.gen.read_register('h07);
    env.gen.read_register('h08);
    env.gen.read_register('h09);
    env.gen.read_register('h10);
    env.gen.read_register('h11);

    env.gen.write_register('h09, 'hFF);
    env.gen.write_register('h11, 'hFF);

    env.gen.write_register('h09, 'h00);
    env.gen.write_register('h11, 'h00);

     env.gen.write_register_random('h11);
    env.gen.write_register_random('h09);

     env.gen.write_register_random('h11);
    env.gen.write_register_random('h09);

    env.gen.write_register('h01, 'hAA%8+1);
    env.gen.write_register('h02, 'hAA%8+1);
    env.gen.write_register('h03, 'hAA%8+1);
    env.gen.write_register('h04, 'hAA%8+1);
    env.gen.write_register('h05, 'hAA%8+1);
    env.gen.write_register('h06, 'hAA%8+1);
    env.gen.write_register('h07, 'hAA%8+1);
    env.gen.write_register('h08, 'hAA%8+1);
    env.gen.write_register('h09, 'hAA);
    env.gen.write_register('h11, 'hAA);

    env.gen.read_register('h01);
    env.gen.read_register('h02);
    env.gen.read_register('h03);
    env.gen.read_register('h04);
    env.gen.read_register('h05);
    env.gen.read_register('h06);
    env.gen.read_register('h07);
    env.gen.read_register('h08);
    env.gen.read_register('h09);
    env.gen.read_register('h10);
    env.gen.read_register('h11);



    //calling run of env, it interns calls generator and driver main tasks.
    env.run();
  end
endprogram
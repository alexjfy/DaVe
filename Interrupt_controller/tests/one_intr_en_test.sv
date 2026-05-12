`include "environment.sv"

program test1(apb_interface apb_if, out_interface out_if);

  environment env;

  initial begin
     //creating environment
    env = new(apb_if, out_if);

    //setting the repeat count of generator as 4, means to generate 4 packets
    //env.gen.repeat_count = 10;

    env.gen.write_register('h11, 'h1);
    env.gen.write_register('h01, 'h2);
    env.gen.write_register('h11, 'h1);
    env.gen.write_register('h02, 'h8);
    env.gen.write_register('h03, 'h1);
    env.gen.write_register('h04, 'h4);
    env.gen.write_register('h05, 'h3);
    env.gen.write_register('h06, 'h5);
    env.gen.write_register('h07, 'h7);
    env.gen.write_register('h08, 'h6);
    env.gen.write_register('h09, 'h1);
    //calling run of env, it interns calls generator and driver main tasks.
    env.run();
  end
endprogram
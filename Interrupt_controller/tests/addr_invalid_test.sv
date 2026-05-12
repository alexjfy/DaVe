`include "environment.sv"

program test4(apb_interface apb_if, out_interface out_if);

  environment env;

  initial begin
    //creating environment
    env = new(apb_if, out_if);

    //setting the repeat count of generator as 4, means to generate 4 packets
    //env.gen.repeat_count = 10;

    env.gen.write_register_random('h12);
    env.gen.write_register_random('h25);
    env.gen.read_register('h25);
    env.gen.write_register_random('h14);
    env.gen.read_register('h14);
    env.gen.write_register_random('h37);
    env.gen.read_register('h37);


    //calling run of env, it interns calls generator and driver main tasks.
    env.run();
  end
endprogram
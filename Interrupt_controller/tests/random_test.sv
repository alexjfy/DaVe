`include "environment.sv"

program test2(apb_interface apb_if, out_interface out_if);

  environment env;

  initial begin
    //creating environment
    env = new(apb_if, out_if);

     env.gen.write_register('h01, 'h2);
    env.gen.write_register_random('h11);
    env.gen.write_all_priority_reg();
    env.gen.write_register_random('h09);
    //calling run of env, it interns calls generator and driver main tasks.
    env.run();
  end
endprogram

`include "environment.sv"
program test(out_interface out_interface_inst, apb_interface apb_interface_inst);

  //declaring environment instance
  environment env;

  initial begin
    //creating environment
    env = new(out_interface_inst , apb_interface_inst);

    env.gen.write_register ( 0, 8'b10000000);
    env.gen.read_register(0);
    env.gen.write_register ( 2, 8'b00001111);
    env.gen.read_register(2);

    //calling run of env, it interns calls generator and driver main tasks.
    env.run();
  end
endprogram

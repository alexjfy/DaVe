
`include "environment.sv"
program test(out_interface out_interface_inst, apb_interface apb_interface_inst);

  //declaring environment instance
  environment env;

  initial begin
    //creating environment
    env = new(out_interface_inst , apb_interface_inst);

    env.gen.write_register ( 0, 8'b00000100);
    env.gen.read_register(0);

    //calling run of env, it interns calls generator and driver main tasks.
    env.run();
  end
endprogram

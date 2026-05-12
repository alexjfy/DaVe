
`include "environment.sv"
program test(out_interface out_interface_inst, apb_interface apb_interface_inst);

  //declaring environment instance
  environment env;

  initial begin
    //creating environment
    env = new(out_interface_inst , apb_interface_inst);

    //setting the repeat count of generator as 4, means to generate 4 packets
    env.gen.repeat_count = 4;

    //calling run of env, it interns calls generator and driver main tasks.
    env.run();
  end
endprogram

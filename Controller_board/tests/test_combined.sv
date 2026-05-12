
`include "environment.sv"
program test(out_interface out_interface_inst, apb_interface apb_interface_inst);

  //declaring environment instance
  environment env;

  initial begin
    //creating environment
    env = new(out_interface_inst , apb_interface_inst);

    //calling run of env, it interns calls generator and driver main tasks.
    fork
    env.run();
    join_none

    env.gen.write_register ( 0, 8'b00100000);
    env.gen.read_register(0);
    repeat (10)@(posedge out_interface_inst.clk);
    env.gen.write_register ( 0, 8'b00110000);
    env.gen.read_register(0);
    repeat (9)@(posedge out_interface_inst.clk);
    env.gen.write_register ( 2, 52);
    env.gen.read_register(2);
    repeat (2)@(posedge out_interface_inst.clk);
    env.gen.write_register ( 0, 8'b10111111);
    env.gen.read_register(0);
    repeat (5)@(posedge out_interface_inst.clk);
    env.gen.write_register ( 0, 8'b10100101);
    env.gen.read_register(0);
    repeat (3)@(posedge out_interface_inst.clk);
    env.gen.write_register ( 2, 210);
    env.gen.read_register(2);
    repeat (7)@(posedge out_interface_inst.clk);
    env.gen.write_register ( 0, 8'b11110101);
    env.gen.read_register(0);
    repeat (8)@(posedge out_interface_inst.clk);
    env.gen.write_register ( 2, 225);
    env.gen.read_register(2);

    #3000;

  end
endprogram

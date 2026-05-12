//-------------------------------------------------------------------------
//				www.verificationguide.com   testbench.sv
//-------------------------------------------------------------------------
//tbench_top or testbench top, this is the top most file, in which DUT(Design Under Test) and Verification environment are connected. 
//-------------------------------------------------------------------------
//including interface and testcase files
`include "apb_interface.sv"
`include "buttons_interface.sv"
`include "output_interface.sv"

// select which test to run by uncommenting the desired include
//`include "random_test.sv"
//`include "onebutton_test.sv"
`include "all_modes_test.sv"
//`include "default_rd_test.sv"


module testbench;
  
  //clock and reset signal declaration
  bit clk;
  bit reset;
  
  //clock generation
  always #5 clk = ~clk;
  
  //reset Generation
  initial begin
    reset = 1;
    #15 reset =0;
  end
  
  
  //creating instance of interface, in order to connect DUT and testcase

  apb_interface apb_vif(clk,reset);
  output_interface out_vif(clk,reset);
  buttons_interface buttons_vif(clk,reset);
  //instantiate all interfaces with clock and reset
  //Testcase instance, interface handle is passed to test as an argument
  test t1(apb_vif, out_vif, buttons_vif);

  boiler_controller i_boiler_controller (
    .clk             (clk       ),
    .rst             (reset     ),
    .button_econ      (buttons_vif.button_mod_econ     ),
    .button_comf      (buttons_vif.button_mod_comf     ),
    .button_thermo   (buttons_vif.button_mod_thermo),
    .child_protection (buttons_vif.button_child_prot   ),
    .psel            (apb_vif.psel    ),
    .penable         (apb_vif.penable ),
    .pwrite          (apb_vif.pwrite  ),
    .paddr           (apb_vif.paddr   ),
    .pwdata          (apb_vif.pwdata  ),
    .pready          (apb_vif.pready  ),
    .prdata          (apb_vif.prdata  ),
    .led             (               ),
    .flame         (out_vif.flame_on),
    .enable_c        (               )
  );
  //enabling the wave dump
  initial begin 
    $dumpfile("dump.vcd"); $dumpvars;
  end
endmodule
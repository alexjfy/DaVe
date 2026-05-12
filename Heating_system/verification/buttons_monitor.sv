//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//the buttons_monitor observes traffic on DUT interfaces, captures data and reconstructs transactions; captured data is sent to the scoreboard for verification
//Samples the interface signals, captures into transaction packet and send the packet to scoreboard.

//the BUTTONS_MONITOR_IF macro holds the signal block from which the monitor extracts data
`define BUTTONS_MONITOR_IF buttons_vif.MONITOR.monitor_cb
class buttons_monitor; 
  
  //creating virtual interface handle
  virtual buttons_interface buttons_vif;
  
  //create the port through which the monitor sends collected DUT interface data to the scoreboard as transactions
  //creating mailbox handle
  mailbox mon2scb;

  //coverage collector
  buttons_coverage buttons_coverage_colector;

  //when the monitor object is created (in environment.sv), its data collection interface is connected to the actual DUT interface
  //constructor
  function new(virtual buttons_interface buttons_vif,mailbox mon2scb);
    //getting the interface
    this.buttons_vif = buttons_vif;
    //getting the mailbox handles from  environment
    this.mon2scb = mon2scb;
    buttons_coverage_colector = new();
  endfunction
  
  // samples all four button signals every clock cycle and forwards the
  // captured transaction to both the scoreboard and the coverage collector
  task main;
    forever begin
      buttons_transaction trans;
      trans = new();

      @(posedge buttons_vif.clk);
        trans.button_mod_econ   = `BUTTONS_MONITOR_IF.button_mod_econ;
        trans.button_mod_comf   = `BUTTONS_MONITOR_IF.button_mod_comf;
        trans.button_mod_thermo = `BUTTONS_MONITOR_IF.button_mod_thermo;
        trans.button_child_prot = `BUTTONS_MONITOR_IF.button_child_prot;

      mon2scb.put(trans);
      buttons_coverage_colector.sample(trans);
    end
  endtask
  
endclass
//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//the monitor observes traffic on DUT interfaces, captures data and reconstructs transactions; captured data is sent to the scoreboard for verification
//Samples the interface signals, captures into transaction packet and send the packet to scoreboard.

//the OUTPUTMON_IF macro holds the signal block from which the monitor extracts data
`define OUTPUTMON_IF mon_vif.MONITOR.monitor_cb
class output_monitor;
  
  //creating virtual interface handle
  virtual output_interface mon_vif;
  
  //create the port through which the monitor sends collected DUT interface data to the scoreboard as transactions
  //creating mailbox handle
  mailbox mon2scb;
  
  output_coverage output_coverage_colector;
  
  
  //when the monitor object is created (in environment.sv), its data collection interface is connected to the actual DUT interface
  //constructor
  function new(virtual output_interface mon_vif,mailbox mon2scb);
    //getting the interface
    this.mon_vif = mon_vif;
    //getting the mailbox handles from  environment 
    this.mon2scb = mon2scb;
    output_coverage_colector = new();
  endfunction
  
  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin
      //declare and create the transaction object that will hold data captured from the interface
      output_transaction trans;
      trans = new();

      //data is sampled on the clock edge, signal information is stored in the transaction object
      @(posedge mon_vif.MONITOR.clk);
        trans.unit_on  = `OUTPUTMON_IF.flame_on;
       
           
      // after capturing transaction information, the trans object contents are sent to the scoreboard
        mon2scb.put(trans);
      output_coverage_colector.sample(trans);
    end
  endtask
  
endclass
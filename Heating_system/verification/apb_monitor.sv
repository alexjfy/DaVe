//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//the monitor observes traffic on DUT interfaces, captures verified data and reconstructs transactions (using transaction class objects); in this implementation, data captured from interfaces is sent to the scoreboard for verification
//Samples the interface signals, captures into transaction packet and send the packet to scoreboard.

//the APBMON_IF macro holds the signal block from which the monitor extracts data
`define APBMON_IF mon_vif.MONITOR.monitor_cb
class apb_monitor;
  
  //creating virtual interface handle
  virtual apb_interface mon_vif;
  
  //create the port through which the monitor sends collected DUT interface data to the scoreboard as transactions
  //creating mailbox handle
  mailbox mon2scb;
  
  apb_coverage apb_coverage_colector;
  
  //when the monitor object is created (in environment.sv), its data collection interface is connected to the actual DUT interface
  //constructor
  function new(virtual apb_interface mon_vif,mailbox mon2scb);
    //getting the interface
    this.mon_vif = mon_vif;
    //getting the mailbox handles from  environment 
    this.mon2scb = mon2scb;
    apb_coverage_colector = new();
    
  endfunction
  
  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin
      //declare and create the transaction object that will hold data captured from the interface
      apb_transaction trans;
      trans = new();

      //data is sampled on the clock edge, signal information is stored in the transaction object
      @(posedge mon_vif.MONITOR.clk);
      wait(`APBMON_IF.penable || `APBMON_IF.pwrite);
        trans.paddr  = `APBMON_IF.paddr;
        trans.pwrite = `APBMON_IF.pwrite;
        trans.data = `APBMON_IF.pwdata;
      if(`APBMON_IF.pwrite == 0) begin
          trans.data = `APBMON_IF.prdata; 
      end
      else if (`APBMON_IF.pwrite == 1)  begin
          trans.data = `APBMON_IF.pwdata;
      end
     
      // after capturing transaction information, the trans object contents are sent to the scoreboard
        mon2scb.put(trans);
      apb_coverage_colector.sample(trans);
    end
  endtask
  
endclass
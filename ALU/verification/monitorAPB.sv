//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//The monitor observes traffic on the DUT interfaces, captures verified data and reconstructs transactions
//(using transaction class objects); in this implementation, captured data is sent to the scoreboard for checking.
//Samples the interface signals, captures into transaction packet and sends the packet to scoreboard.

//Macro MON_IF holds the clocking block from which the monitor extracts data
`define MON_IF_APB apb_vif.MONITOR.monitor_cb
class monitorAPB;
  
  //creating virtual interface handle
  virtual apb_interface apb_vif;
  
  //Mailbox through which the monitor sends collected interface data to the scoreboard as transactions
  //creating mailbox handle
  mailbox mon2scb;
  
  coverageAPB coverage_collector;
  
  //When the monitor object is created (in environment.sv), the virtual interface is connected to the DUT's actual interface
  //constructor
  function new(virtual apb_interface apb_vif,mailbox mon2scb);
    //getting the interface
    this.apb_vif = apb_vif;
    //getting the mailbox handles from  environment 
    this.mon2scb = mon2scb;
    
    coverage_collector = new();
  endfunction
  
  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin
      //Declare and create the transaction object that will hold data captured from the interface
      transactionAPB trans;
      trans = new();

      //Data is sampled on the clock edge; information captured from signals is stored in the transaction object
      @(posedge apb_vif.MONITOR.clk iff `MON_IF_APB.psel);
        trans.addr  = `MON_IF_APB.paddr;
        trans.write = `MON_IF_APB.pwrite;
      if(trans.write) trans.data = `MON_IF_APB.pwdata;
        wait(`MON_IF_APB.penable===1'b1)
        wait(`MON_IF_APB.pready===1'b1);
      trans.slaveRsp = `MON_IF_APB.pslverr;
      if(!trans.write) trans.data = `MON_IF_APB.prdata;
      //After transaction information is captured, the trans object is sent to the scoreboard
      coverage_collector.sample(trans);
      mon2scb.put(trans);
    
    end
  endtask
  
endclass
//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//The monitor observes traffic on the DUT interfaces, captures verified data and reconstructs transactions
//(using transaction class objects); in this implementation, captured data is sent to the scoreboard for checking.
//Samples the interface signals, captures into transaction packet and sends the packet to scoreboard.

//Macro MON_IF holds the clocking block from which the monitor extracts data
`define MON_IF vif.MONITOR.monitor_cb
class result_monitor;
  
  //creating virtual interface handle
  virtual output_interface vif;
  
  result_coverage coverage_collector;
  
  //Mailbox through which the monitor sends collected interface data to the scoreboard as transactions
  //creating mailbox handle
  mailbox mon2scb;
  
  //When the monitor object is created (in environment.sv), the virtual interface is connected to the DUT's actual interface
  //constructor
  function new(virtual output_interface vif,mailbox mon2scb);
    //getting the interface
    this.vif = vif;
    //getting the mailbox handles from  environment 
    this.mon2scb = mon2scb;
    
    coverage_collector = new();
  endfunction
  
  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin
      //Declare and create the transaction object that will hold data captured from the interface
      result_transaction result_trans;
      result_trans = new();

      //Data is sampled on the clock edge; information captured from signals is stored in the transaction object
      while(~`MON_IF.valid)
        @(posedge vif.clk);
      result_trans.result = `MON_IF.result;
      $display("T=%0t [RESULT_MON] result=%0d (0x%0h), valid=1", $time, result_trans.result, result_trans.result);
    
     
      //After transaction information is captured, the trans object is sent to the scoreboard
      mon2scb.put(result_trans);
      coverage_collector.sample(result_trans);
      @(posedge vif.clk);
    end
  endtask
  
endclass
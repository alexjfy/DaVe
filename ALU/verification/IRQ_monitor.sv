//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//The monitor observes traffic on the DUT interfaces, captures verified data and reconstructs transactions
//(using transaction class objects); in this implementation, captured data is sent to the scoreboard for checking.
//Samples the interface signals, captures into transaction packet and sends the packet to scoreboard.

//Macro MON_IRQ_IF holds the clocking block from which the monitor extracts data
`define MON_IRQ_IF irq_vif.MONITOR.monitor_cb

class IRQ_monitor;
  
  
  //creating virtual interface handle
  virtual irq_interface irq_vif;
  
  //Mailbox through which the monitor sends collected interface data to the scoreboard as transactions
  //creating mailbox handle
  mailbox mon2scb;
  
  irq_coverage coverage_collector;
  
  //When the monitor object is created (in environment.sv), the virtual interface is connected to the DUT's actual interface
  //constructor
  function new(virtual irq_interface irq_vif,mailbox mon2scb);
    //getting the interface
    this.irq_vif = irq_vif;
    //getting the mailbox handles from  environment 
    this.mon2scb = mon2scb;
    coverage_collector = new();
  endfunction
  
  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin
      //Declare and create the transaction object that will hold data captured from the interface
      IRQ_transaction irq_trans;
      irq_trans = new();

      //Data is sampled on the clock edge; information captured from signals is stored in the transaction object
      @(posedge irq_vif.MONITOR.clk);
      irq_trans.irq =  `MON_IRQ_IF.irq;
      if(irq_trans.irq)
        $display("T=%0t [IRQ_MON] IRQ=1 (interrupt active!)", $time);
      //After transaction information is captured, the trans object is sent to the scoreboard
        mon2scb.put(irq_trans);
      coverage_collector.sample(irq_trans);
    end
  endtask
  
endclass
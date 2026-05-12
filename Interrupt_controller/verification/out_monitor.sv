//the monitor observes traffic on the DUT interfaces, captures the data and reconstructs transactions (using transaction class objects); in this implementation, captured data is sent to the scoreboard for verification
//Samples the interface signals, captures into transaction packet and send the packet to scoreboard.

//the MON_IF macro holds the signal block from which the monitor extracts data
`define MON_IF out_vif.MONITOR.monitor_cb
class out_monitor;

  //creating virtual interface handle
  virtual out_interface out_vif;

  //mailbox port through which the monitor sends collected DUT interface data to the scoreboard as transactions
  //creating mailbox handle
  mailbox mon2scb;

  out_coverage out_coverage_inst;

  //when the monitor object is created (in environment.sv), its collection interface is connected to the actual DUT interface
  //constructor
  function new(virtual out_interface out_vif,mailbox mon2scb);
     //getting the interface
    this.out_vif = out_vif;
    //getting the mailbox handles from  environment
    this.mon2scb = mon2scb;

      out_coverage_inst = new();
  endfunction

  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin
      //declare and create the transaction object that will hold the data captured from the interface
      out_transaction trans;
      trans = new();

       //wait for an irq_flag pulse, then latch the interrupt code into the transaction object
      @(posedge out_vif.MONITOR.clk iff `MON_IF.irq_flag);
        trans.irq  = `MON_IF.irq;

      $display("[OUT_MON] %0t Captured: irq=%0d, irq_flag=1", $time, trans.irq);
      out_coverage_inst.sample(trans); // feed output coverage before forwarding
        mon2scb.put(trans);
    end
  endtask

endclass
// The monitor observes traffic on the DUT interfaces, captures verified data
// and reconstructs transactions (using transaction class objects); in this
// implementation, the captured data is sent to the scoreboard for verification.
// Samples the interface signals, captures into transaction packet and send the packet to scoreboard.

// The APB_MON_IF macro holds the signal block from which the monitor extracts data
`define APB_MON_IF apb_vif.MONITOR.monitor_cb
class apb_monitor;

  apb_coverage  covera;

  //creating virtual interface handle
  virtual apb_interface apb_vif;

  // Mailbox port through which the monitor sends collected data to the scoreboard as transactions
  //creating mailbox handle
  mailbox mon2scb;


  int transaction_counter = 0;
  // When the monitor object is created (in environment.sv), the interface from which
  // it collects data is connected to the actual DUT interface
  //constructor
  function new(virtual apb_interface apb_vif,mailbox mon2scb);
    //getting the interface
    this.apb_vif = apb_vif;
    //getting the mailbox handles from  environment
    this.mon2scb = mon2scb;
     covera = new();
  endfunction

  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin
      // Declare and create the transaction object that will hold the captured interface data
      apb_transaction trans;
      trans = new();

      // Data is read on the clock edge, captured signal values are stored in the transaction object
      @(posedge apb_vif.MONITOR.clk iff `APB_MON_IF.pready == 1);
        trans.address  = `APB_MON_IF.paddr;
        trans.write_enable = `APB_MON_IF.pwrite;

      if(`APB_MON_IF.pwrite == 1)
        trans.data = `APB_MON_IF.pwdata;
      else
        trans.data = `APB_MON_IF.prdata;

      $display("[Monitor] sampled trans #%0d: %s addr=0x%0h data=0x%0h",
               transaction_counter, trans.write_enable ? "WRITE" : "READ",
               trans.address, trans.data);
      trans.transaction_number = transaction_counter;
       transaction_counter ++;

      // After capturing a transaction's information, the trans object content is sent to the scoreboard
        mon2scb.put(trans);
      covera.sample(trans);
    end
  endtask

endclass

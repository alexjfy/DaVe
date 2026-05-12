//the monitor observes traffic on the DUT interfaces, captures the data and reconstructs transactions (using transaction class objects); in this implementation, captured data is sent to the scoreboard for verification
//Samples the interface signals, captures into transaction packet and send the packet to scoreboard.

//the APB_MON_IF macro holds the signal block from which the monitor extracts data
`define APB_MON_IF apb_vif.MONITOR.monitor_cb
class apb_monitor#(int AW=32, DW=32);

  //creating virtual interface handle
  virtual apb_interface apb_vif;

  //mailbox port through which the monitor sends collected DUT interface data to the scoreboard as transactions
  //creating mailbox handle
  mailbox mon2scb;
   apb_coverage apb_coverage_inst;

  //when the monitor object is created (in environment.sv), its collection interface is connected to the actual DUT interface
  // constructor
  function new(virtual apb_interface apb_vif,mailbox mon2scb);
    //getting the interface
    this.apb_vif = apb_vif;
    //getting the mailbox handles from  environment
    this.mon2scb = mon2scb;
    apb_coverage_inst = new();
  endfunction

  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin
       //declare and create the transaction object that will hold the data captured from the interface
      apb_transaction#(AW,DW) trans;
      trans = new();

      //data is sampled on the clock edge, information captured from signals is stored in the transaction object
      @(posedge apb_vif.MONITOR.clk iff `APB_MON_IF.psel);
        trans.addr  = `APB_MON_IF.paddr;
      trans.kind = (`APB_MON_IF.pwrite == 1'b1) ? APB_WRITE : APB_READ;
      if(trans.kind == APB_WRITE)
        trans.data = `APB_MON_IF.pwdata;
      wait (`APB_MON_IF.penable === 1'b1);
      wait (`APB_MON_IF.pready === 1'b1);
      if (trans.kind == APB_READ)
        trans.data = `APB_MON_IF.prdata;
      // after capturing the transaction information, the trans object content is sent to the scoreboard
      apb_coverage_inst.sample(trans);
      mon2scb.put(trans);
    end
  endtask

endclass
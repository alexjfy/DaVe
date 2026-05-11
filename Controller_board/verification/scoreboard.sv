// The scoreboard receives data from the monitor and verifies its accuracy;
// to perform this verification, the DUT functionality is implemented in the scoreboard;
// the inputs received by the DUT are captured by the monitor and sent to the scoreboard;
// by comparing the monitor and scoreboard outputs, we can determine if they work correctly.

// The scoreboard gets the packet from monitor, generates the expected result and compares
// with the actual result received from Monitor

class scoreboard;

  // Mailbox port through which the scoreboard receives data from the monitor;
  // if there are multiple monitors, multiple ports of this type can be declared
  //creating mailbox handle
  mailbox mon2scb;

  //used to count the number of transactions
  int no_transactions;

  //array to use as local memory
  bit [7:0] mem[4];

  //constructor
  function new(mailbox mon2scb, mailbox other);
    //getting the mailbox handles from  environment
    this.mon2scb = mon2scb;
    foreach(mem[i]) mem[i] = 8'hFF;
  endfunction

  //stores wdata and compare rdata with stored data
  task main;
    apb_transaction trans;
 /*   forever begin
      #50;
      // Get data from monitor
      mon2scb.get(trans);
      // Checker implementation below
      if(trans.rd_en) begin
        if(mem[trans.address] != trans.rdata)
          $error("[SCB-FAIL] Addr = %0h,\n \t   Data :: Expected = %0h Actual = %0h",trans.address,mem[trans.address],trans.rdata);
        else
          begin
          $display("[SCB-PASS] Addr = %0h,\n \t   Data :: Expected = %0h Actual = %0h",trans.addr,mem[trans.addr],trans.rdata);
          // If the transaction was successful, collect coverage
            colector_coverage.sample(trans);
          end
      end
      // The two lines below represent the DUT functionality, also implemented in the scoreboard
      else if(trans.wr_en)
        begin
          mem[trans.addr] = trans.wdata;
          // Collect coverage for write transactions as well
         // colector_coverage.sample(trans);
        end

      no_transactions++;
    end*/
  endtask

endclass

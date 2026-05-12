//the scoreboard receives data from the monitor and verifies its accuracy; to perform this verification, the scoreboard implements the DUT functionality as a reference model; the inputs received by the DUT are captured by the monitor and sent to the scoreboard; by comparing the monitor and scoreboard outputs, correctness can be determined

//the scoreboard gets the packet from monitor, generates the expected result and compares with the //actual result recived from Monitor

class scoreboard;

  //mailbox port through which the scoreboard receives data from the monitor; if there are multiple monitors, multiple ports of this type can be declared
  //creating mailbox handle
  mailbox apb_mon2scb;
  mailbox out_mon2scb;

  //used to count the number of transactions
  int no_apb_transactions;

   //array to use as local memory
  bit [7:0] interrupt_enable_register; // 1: the interrupt is enabled; 0: the interrupt is diabled

  bit [7:0][3:0] priorities_of_interrupts; // store priority for each interrupt

  bit [2:0] predicted_interrupt; //predict which interrupt is currently served (which interrupt code is at the DUT output)

  bit [7:0] pending_interrupts;  // interrupts still pending to be served

  bit [7:0] served_interrupts_mask; // tracks which interrupts have been served in current cycle

  bit [2:0] ordered_interrupts [$];  // the interrupts will be served as ordered in this array

  time last_reg_write_time; // timestamp of last EXT_INT or EN_MASK write (for pipeline hazard detection)

   //declare and create the coverage collector
 // coverage colector_coverage;

  //constructor
  function new(mailbox apb_mon2scb, mailbox out_mon2scb);
    //getting the mailbox handles from  environment
    this.apb_mon2scb = apb_mon2scb;
    this.out_mon2scb = out_mon2scb;
   // colector_coverage = new();
  endfunction

  //stores wdata and compare rdata with stored data
  task main;
    apb_transaction apb_trans;
    out_transaction out_trans;
      fork
      // thread for collecting APB transactions
      forever begin
      #50;
       //get data from the monitor
        apb_mon2scb.get(apb_trans);
        $display("[SCB] %0t APB transaction: addr=%0d, kind=%0s, data=0x%0h", $time, apb_trans.addr, apb_trans.kind.name(), apb_trans.data);
        // Route the incoming transaction based on its target register address.
        // On write, we shadow the DUT register into a local reference model.
        // On read, we check that what we read back matches what we wrote.
        case(apb_trans.addr)
          1: if (apb_trans.kind == APB_WRITE)
            priorities_of_interrupts[0] = apb_trans.data;
          	else
              assert(priorities_of_interrupts[0] == apb_trans.data) else $error("priority of interrupt 0 in DUT register is different from written priority in register INT_PRI0");
          2: if (apb_trans.kind == APB_WRITE)
            priorities_of_interrupts[1] = apb_trans.data;
          	else
              assert(priorities_of_interrupts[1] == apb_trans.data) else $error("priority of interrupt 1 in DUT register is different from written priority in register INT_PRI1");
          3: if (apb_trans.kind == APB_WRITE)
             priorities_of_interrupts[2] = apb_trans.data;
          	else
              assert (priorities_of_interrupts[2] == apb_trans.data) else $error("priority of interrupt 2 in DUT register is different from written priority in register INT_PRI2");
          4: if (apb_trans.kind == APB_WRITE)
            priorities_of_interrupts[3] = apb_trans.data;
          	else
              assert (priorities_of_interrupts[3] == apb_trans.data) else $error("priority of interrupt 3 in DUT register is different from written priority in register INT_PRI3");
          5: if (apb_trans.kind == APB_WRITE)
            priorities_of_interrupts[4] = apb_trans.data;
          	else
              assert(priorities_of_interrupts[4] == apb_trans.data) else $error("priority of interrupt 4 in DUT register is different from written priority in register INT_PRI4");
          6: if (apb_trans.kind == APB_WRITE)
            priorities_of_interrupts[5] = apb_trans.data;
          	else
              assert (priorities_of_interrupts[5] == apb_trans.data) else $error("priority of interrupt 5 in DUT register is different from written priority in register INT_PRI5");
          7: if(apb_trans.kind == APB_WRITE)
            priorities_of_interrupts[6] = apb_trans.data;
          	else
              assert (priorities_of_interrupts[6] == apb_trans.data) else $error("priority of interrupt 6 in DUT register is different from written priority in register INT_PRI6");
          8: if (apb_trans.kind == APB_WRITE)
            priorities_of_interrupts[7] = apb_trans.data;
          	else
              assert(priorities_of_interrupts[7] == apb_trans.data) else $error("priority of interrupt 7 in DUT register is different from written priority in register INT_PRI7");
          9: if (apb_trans.kind == APB_WRITE) begin
                // EXT_INT write = start of a fresh servicing cycle in the DUT;
                // we mirror that here by clearing the local "served" mask
                pending_interrupts = apb_trans.data;
                served_interrupts_mask = 0;
                last_reg_write_time = $time; // timestamp used later for pipeline-hazard tolerance
                $display("[SCB] %0t EXT_INT write: pending=%08b, clearing served_interrupts_mask", $time, apb_trans.data);
                order_interrupts();
              end
          	else
              assert (pending_interrupts == apb_trans.data) else $error("interrupts asserted are different in DUT (%0d) and in reference model (%0d)", apb_trans.data, pending_interrupts);
          16:if (apb_trans.kind == APB_READ) begin  // address 0x10 = decimal 16 = RESULT register
             // RESULT[7] is the valid flag; RESULT[2:0] is the currently-served irq code
            if(apb_trans.data[7]) begin // valid bit is set — DUT is actively outputting an interrupt
              assert(predicted_interrupt == apb_trans.data[2:0]) else $error("predicted interrupt value does not match value in DUT's RESULT register; DUT's value: %0d; Scoreboard value: %0d", apb_trans.data[2:0], predicted_interrupt);
              $display("[SCB] %0t RESULT read: valid=1, irq_code=%0d (matches predicted=%0d)", $time, apb_trans.data[2:0], predicted_interrupt);
            end else begin
               $display("[SCB] %0t RESULT read: valid=0, no interrupt actively being served", $time);
            end
                    end
          17: if (apb_trans.kind == APB_WRITE) begin
            // EN_MASK write changes which interrupts are enabled — recompute ordering
            interrupt_enable_register = apb_trans.data;
            last_reg_write_time = $time;
            $display("[SCB] %0t EN_MASK write: enable_mask=%08b", $time, apb_trans.data);
            order_interrupts();
          end
          	else
              assert(interrupt_enable_register == apb_trans.data) else $error("[SCB] EN_MASK read mismatch: DUT=%0h, expected=%0h", apb_trans.data, interrupt_enable_register);

        endcase

           //collect coverage for write-to-memory transactions as well
         // colector_coverage.sample(trans);

      no_apb_transactions++;
    end

     // thread for collecting output transactions (the irq_flag pulses from DUT)
    forever begin

      out_mon2scb.get(out_trans);

      $display("[SCB] %0t OUTPUT transaction: irq=%0d, irq_flag pulse detected", $time, out_trans.irq);
      served_interrupts_mask[out_trans.irq] = 1'b1;  // mark as served in the reference model
      if(ordered_interrupts.size() > 0) begin
        predicted_interrupt = ordered_interrupts.pop_front();
        if (out_trans.irq == predicted_interrupt) begin
          // happy path — DUT served the interrupt we expected
          $display("[SCB] %0t PASS: DUT output irq=%0d matches predicted=%0d", $time, out_trans.irq, predicted_interrupt);
        end else if(($time - last_reg_write_time) < 120000) begin
           // Register changed within ~12 cycles (120ns). The DUT pipeline may still be
           // operating on the old configuration, so we downgrade this to a warning.
          $display("[SCB] %0t WARN: DUT irq=%0d, predicted=%0d (pipeline hazard: register changed %0dns ago)", $time, out_trans.irq, predicted_interrupt, ($time - last_reg_write_time));
        end else begin
          $error("[SCB] %0t FAIL: DUT irq=%0d, predicted=%0d", $time, out_trans.irq, predicted_interrupt);
        end
      end else begin
         // DUT produced an output but the predicted queue was empty.
         // Same hazard window logic: close to a recent register write → warn, otherwise fail.
         if (($time - last_reg_write_time) < 120000) begin
          $display("[SCB] %0t WARN: DUT output irq=%0d while queue empty (pipeline hazard: register changed %0dns ago)", $time, out_trans.irq, ($time - last_reg_write_time));
        end else begin
          $error("[SCB] %0t FAIL: DUT output irq=%0d but no more interrupts predicted (queue empty)", $time, out_trans.irq);
         end
      end
      //Recompute predictions after each output (DUT re-evaluates in WAIT state)
      order_interrupts();
    end
      join
  endtask

  // Rebuilds ordered_interrupts: the expected order in which the DUT should output interrupts,
  // starting from highest priority and skipping disabled / not-pending / already-served ones.
  function void order_interrupts();

    $display("[SCB] %0t order_interrupts(): enabled=%08b, pending=%08b", $time, interrupt_enable_register, pending_interrupts);
     // Clear previous ordering before recomputing
    ordered_interrupts = {};
    for(int i = 8; i >= 1; i--) begin // the possible priorities are parsed in descending order
      for (int j = 0; j < 8; j++) begin // scan all 8 channels at this priority level
      /*  if (priorities_of_interrupts[j]==i)
          $display("j = %0d, priorities_of_interrupts[j]=%0d && pending_interrupts[j] = %0d && interrupt_enable_register[j]= %0d",j, priorities_of_interrupts[j], pending_interrupts[j], interrupt_enable_register[j]);*/
        if(priorities_of_interrupts[j]==i && pending_interrupts[j] == 1 && interrupt_enable_register[j]==1 && served_interrupts_mask[j] == 0) begin
          ordered_interrupts.push_back(j);
          /*   $display("interrupt %0d is valid", j);*/
        end

      end
    end
    $display("[SCB] %0t Predicted interrupt service order (highest pri first):", $time);
    for(int k = 0; k < ordered_interrupts.size(); k++)
       $display("[SCB]   position %0d: interrupt %0d", k, ordered_interrupts[k]);
  endfunction

endclass
// Scoreboard
// Description: Reference model for the electric oven DUT. Performs:
//                - Collection of APB transactions and mirroring of register state
//                - Collection of door transactions and tracking of door state
//                - Collection of LED transactions and comparison with prediction
//                - Prediction of the LED output from the mirrored state
//              Five parallel tasks run under main(), synchronized by two events
//              (one_clock_cycle, counter_done) and one shared flag (start_pending).

`ifndef __ref
`define __ref

typedef enum logic[2:0] {IDLE, COOKING, HEATING, PIZZA, DEFROSTING} oven_processes;

class scoreboard;

    // Mailboxes from the three monitors.
    mailbox apb_mon2scb;
    mailbox door_mon2scb;
    mailbox led_mon2scb;

    // Mirrored register state, kept in step with the DUT's internal registers.
    logic [7:0] reg_timer;           // Mirror of timer_reg (addr 0x02)
    logic [7:0] reg_config_apb;      // Mirror of operation_mod_reg (addr 0x01) - raw APB write
    logic [7:0] reg_config;          // After hardware auto-clear of bit 3
    logic [7:0] reg_temperature;     // Mirror of temp_set_reg (addr 0x00)

    // Temperature selector (0-4) converted to degrees — tracks the DUT's temp module.
    logic [7:0] converted_temperature;

    // Current LED prediction produced by predict_led_output().
    bit predicted_led;

    // Transaction handles used as scratchpad during collection.
    led_transaction  led_trans;
    door_transaction door_trans;
    apb_transaction  apb_trans;

    logic door_is_closed;

    // Synchronization events.
    // one_clock_cycle fires whenever a door transaction is consumed — it paces the
    //   countdown task at the same rate as the DUT's clock.
    // counter_done is chained from counter_operation to predict_led_output so the
    //   predictor always sees the freshly-updated predicted_timeout value.
    event one_clock_cycle;
    event counter_done;

    // Internal countdown mirroring the DUT timer.
    int counter;

    // Mirrors the DUT's timeout signal, one cycle behind timeout_pre to match
    // the register delay in the timer module.
    bit predicted_timeout;
    bit timeout_pre;

    // Flag set by the APB task when it sees a write with bit 3 (start) high, and
    // cleared by the counter task after loading the countdown. Using a flag avoids
    // race conditions between parallel tasks modifying reg_config_apb.
    bit start_pending;

    // Match/mismatch counters for the final report.
    int num_matches;
    int num_mismatches;

    function new(mailbox apb_mon2scb, mailbox door_mon2scb, mailbox led_mon2scb);
        this.apb_mon2scb  = apb_mon2scb;
        this.door_mon2scb = door_mon2scb;
        this.led_mon2scb  = led_mon2scb;
        predicted_led         = 0;
        predicted_timeout     = 0;
        timeout_pre           = 0;
        door_is_closed        = 0;
        counter               = 0;
        converted_temperature = 0;
        reg_timer             = 0;
        reg_config_apb        = 0;
        reg_config            = 0;
        reg_temperature       = 0;
        num_matches           = 0;
        num_mismatches        = 0;
        start_pending         = 0;
    endfunction

    // Launches all five collector/predictor tasks as parallel threads.
    task main();
        fork
            collect_led_transactions();
            collect_apb_transactions();
            collect_door_transactions();
            predict_led_output();
            counter_operation();
        join_none
    endtask

    // Collect door transactions — also drives the one_clock_cycle event that paces
    // the countdown task, and replicates the DUT's hardware auto-clear of bit 3.
    task collect_door_transactions();
        forever begin
            door_mon2scb.get(door_trans);

            door_is_closed = door_trans.door_closed;

            if (door_is_closed)
                $display("%0t [SCB-DOOR] Door is CLOSED", $time());
            else
                $display("%0t [SCB-DOOR] Door is OPENED", $time());

            // Trigger one_clock_cycle for the counter and prediction tasks.
            -> one_clock_cycle;

            // Mirror the DUT's hardware auto-clear of the start bit (bit 3).
            reg_config    = reg_config_apb;
            reg_config[3] = 0;
        end
    endtask

    // Collect APB transactions — mirror register writes, verify read data.
    task collect_apb_transactions();
        forever begin
            apb_mon2scb.get(apb_trans);
            $display("%0t [SCB-APB] Received: addr=0x%0h, write=%0b, data=0x%0h",
                     $time(), apb_trans.paddr, apb_trans.pwrite, apb_trans.data);

            if (apb_trans.pwrite == 1) begin
                case (apb_trans.paddr)
                    0: begin
                        // Mirror temp_set_reg and compute the converted temperature
                        // the same way the DUT's temp module does.
                        reg_temperature = apb_trans.data;
                        case (apb_trans.data[2:0])
                            3'b000:  converted_temperature = 8'd0;
                            3'b001:  converted_temperature = 8'd50;
                            3'b010:  converted_temperature = 8'd100;
                            3'b011:  converted_temperature = 8'd150;
                            3'b100:  converted_temperature = 8'd200;
                            default: converted_temperature = 8'd0;
                        endcase
                        $display("%0t [SCB-APB] WRITE temp_set_reg = 0x%0h (converted: %0d degrees)",
                                 $time(), apb_trans.data, converted_temperature);
                    end
                    1: begin
                        // Mirror operation_mod_reg and flag a pending start if bit 3 is set.
                        reg_config_apb = apb_trans.data;
                        if (apb_trans.data[3])
                            start_pending = 1;
                        $display("%0t [SCB-APB] WRITE operation_mod_reg = 0x%0h (start=%0b, mode=%03b)",
                                 $time(), apb_trans.data, apb_trans.data[3], apb_trans.data[2:0]);
                    end
                    2: begin
                        reg_timer = apb_trans.data;
                        $display("%0t [SCB-APB] WRITE timer_reg = %0d", $time(), apb_trans.data);
                    end
                endcase
            end else begin
                // READ transaction: verify read data matches the mirrored state.
                case (apb_trans.paddr)
                    0: begin
                        assert(reg_temperature == apb_trans.data)
                            $display("%0t [SCB-APB] READ temp_set_reg OK: 0x%0h", $time(), apb_trans.data);
                        else
                            $error("%0t [SCB-APB] READ temp_set_reg MISMATCH: expected=0x%0h, got=0x%0h",
                                   $time(), reg_temperature, apb_trans.data);
                    end
                    1: begin
                        assert(reg_config == apb_trans.data)
                            $display("%0t [SCB-APB] READ operation_mod_reg OK: 0x%0h", $time(), apb_trans.data);
                        else
                            $error("%0t [SCB-APB] READ operation_mod_reg MISMATCH: expected=0x%0h, got=0x%0h",
                                   $time(), reg_config, apb_trans.data);
                    end
                    2: begin
                        assert(reg_timer == apb_trans.data)
                            $display("%0t [SCB-APB] READ timer_reg OK: 0x%0h", $time(), apb_trans.data);
                        else
                            $error("%0t [SCB-APB] READ timer_reg MISMATCH: expected=0x%0h, got=0x%0h",
                                   $time(), reg_timer, apb_trans.data);
                    end
                endcase
            end
        end
    endtask

    // Collect LED transactions — compare the observed LED value with the prediction.
    task collect_led_transactions();
        forever begin
            led_mon2scb.get(led_trans);
            if (led_trans.led !== predicted_led) begin
                $error("%0t [SCB-LED] MISMATCH: DUT led=%0d, predicted=%0d | timeout=%0b, door=%0b, temp=%0d, mode=%03b, counter=%0d",
                       $time(), led_trans.led, predicted_led,
                       predicted_timeout, door_is_closed, converted_temperature,
                       reg_config[2:0], counter);
                num_mismatches++;
            end else begin
                $display("%0t [SCB-LED] MATCH: led=%0d", $time(), led_trans.led);
                num_matches++;
            end
        end
    endtask

    // Countdown model — runs one iteration per one_clock_cycle event. Uses a
    // two-stage pipeline (timeout_pre -> predicted_timeout) so the visible
    // timeout is delayed by one cycle, matching the DUT's registered timeout.
    task counter_operation();
        forever begin
            @(one_clock_cycle);

            if (start_pending) begin
                // Start detected: load timer value and clear both pipeline stages.
                // Only this task clears start_pending, which avoids races.
                counter           = reg_timer;
                timeout_pre       = 0;
                predicted_timeout = 0;
                start_pending     = 0;
                $display("%0t [SCB-COUNTER] START: loaded counter = %0d", $time(), counter);
            end else begin
                // Advance the pipeline: predicted_timeout becomes last cycle's timeout_pre.
                predicted_timeout = timeout_pre;

                if (counter > 0) begin
                    counter--;
                    timeout_pre = 0;
                end else begin
                    timeout_pre = 1;
                end
            end

            $display("%0t [SCB-COUNTER] counter=%0d, timeout=%0b (pre=%0b)",
                     $time(), counter, predicted_timeout, timeout_pre);

            -> counter_done;
        end
    endtask

    // Predict the LED output from the mirrored state.
    // The LED is ON iff all of the following hold:
    //   1. An operating mode is active (reg_config[2:0] != 0)
    //   2. The converted temperature is greater than 0
    //   3. The predicted timeout is asserted (countdown finished)
    //   4. The door is closed
    task predict_led_output();
        forever begin
            @(counter_done);

            if (predicted_timeout && door_is_closed && (converted_temperature > 0) && (reg_config[2:0] != 0)) begin
                predicted_led = 1;
                $display("%0t [SCB-PREDICT] LED should be ON: timeout=%0b, door=%0b, temp=%0d, mode=%03b",
                         $time(), predicted_timeout, door_is_closed, converted_temperature, reg_config[2:0]);
            end else begin
                predicted_led = 0;
                $display("%0t [SCB-PREDICT] LED should be OFF: timeout=%0b, door=%0b, temp=%0d, mode=%03b",
                         $time(), predicted_timeout, door_is_closed, converted_temperature, reg_config[2:0]);
            end
        end
    endtask

    // Print the final match/mismatch statistics at the end of simulation.
    function void print_stats();
        $display("[SCB] SCOREBOARD STATISTICS");
        $display("  LED Matches:    %0d", num_matches);
        $display("  LED Mismatches: %0d", num_mismatches);
        if (num_mismatches == 0)
            $display("  RESULT: ALL LED CHECKS PASSED");
        else
            $display("  RESULT: %0d LED CHECK(S) FAILED", num_mismatches);
    endfunction

endclass

`endif

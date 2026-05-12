// APB Driver
// Description: Retrieves transactions from the generator and drives them onto
//              the DUT's APB interface following the three-phase APB protocol:
//                1. SETUP phase   : assert psel, set paddr/pwrite/pwdata, penable=0
//                2. ACCESS phase  : assert penable, wait for pready
//                3. IDLE phase    : deassert all control signals
`define APB_DRIV_IF apb_vif.driver_cb

class apb_driver;

    // Transaction counter used for logging.
    int no_transactions;

    // Virtual interface handle, bound at construction to the testbench interface.
    virtual apb_interface apb_vif;

    // Mailbox connecting the generator (producer) to this driver (consumer).
    mailbox gen2driv;

    // Constructor: receives the shared interface and mailbox from the environment.
    function new(virtual apb_interface apb_vif, mailbox gen2driv);
        this.apb_vif  = apb_vif;
        this.gen2driv = gen2driv;
    endfunction

    // Reset task: drives all APB control signals low while reset is asserted.
    task reset;
        wait(apb_vif.reset);
        $display("%0t [APB-DRIVER] Reset started", $time());
        `APB_DRIV_IF.pwrite  <= 0;
        `APB_DRIV_IF.paddr   <= 0;
        `APB_DRIV_IF.pwdata  <= 0;
        `APB_DRIV_IF.psel    <= 0;
        `APB_DRIV_IF.penable <= 0;
        wait(!apb_vif.reset);
        $display("%0t [APB-DRIVER] Reset ended", $time());
        @(posedge apb_vif.clk);
    endtask

    // Drive one APB transaction according to the protocol.
    task drive;
        apb_transaction trans;

        // Block here until the generator provides a transaction.
        gen2driv.get(trans);
        $display("%0t [APB-DRIVER] Transfer #%0d: addr=0x%0h, write=%0b, data=0x%0h",
                 $time(), no_transactions, trans.paddr, trans.pwrite, trans.data);

        // SETUP phase (cycle T1): assert psel, drive address/direction/data.
        @(posedge apb_vif.clk);
        `APB_DRIV_IF.paddr  <= trans.paddr;
        `APB_DRIV_IF.pwrite <= trans.pwrite;
        if (trans.pwrite == 1) begin
            `APB_DRIV_IF.pwdata <= trans.data;
        end
        `APB_DRIV_IF.psel    <= 1;
        `APB_DRIV_IF.penable <= 0;

        // ACCESS phase (cycle T2): assert penable, then wait for pready.
        @(posedge apb_vif.clk);
        `APB_DRIV_IF.penable <= 1;
        @(posedge apb_vif.clk iff apb_vif.monitor_cb.pready == 1);

        // Log transfer result.
        if (trans.pwrite == 0) begin
            $display("%0t [APB-DRIVER] READ complete: addr=0x%0h, rdata=0x%0h",
                     $time(), trans.paddr, `APB_DRIV_IF.prdata);
        end else begin
            $display("%0t [APB-DRIVER] WRITE complete: addr=0x%0h, wdata=0x%0h",
                     $time(), trans.paddr, trans.data);
        end

        // IDLE phase: deassert all control signals to end the transfer.
        `APB_DRIV_IF.psel    <= 0;
        `APB_DRIV_IF.penable <= 0;
        `APB_DRIV_IF.pwrite  <= 0;
        `APB_DRIV_IF.paddr   <= 0;
        `APB_DRIV_IF.pwdata  <= 0;

        no_transactions++;
    endtask

    // Main task: two parallel threads — one monitors reset, the other drives.
    // When reset is asserted, the drive thread is killed; after deassertion it restarts.
    task main;
        forever begin
            fork
                // Thread 1: handle reset.
                begin
                    reset();
                end
                // Thread 2: drive transactions while reset is inactive.
                begin
                    forever begin
                        wait(apb_vif.reset === 0);
                        drive();
                    end
                end
            join_any
            disable fork;
        end
    endtask

endclass

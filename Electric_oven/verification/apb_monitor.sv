// APB Monitor
// Description: Observes APB bus traffic and captures every completed transfer.
//              A transfer is considered complete on the clock edge where pready
//              is high. The captured transaction is sent to the scoreboard and
//              also fed to the coverage collector.
`define APB_MON_IF apb_vif.monitor_cb

class apb_monitor;

    // Virtual interface handle, bound at construction.
    virtual apb_interface apb_vif;

    // Coverage collector instantiated alongside this monitor.
    apb_coverage coverage_collector;

    // Mailbox through which captured transactions are sent to the scoreboard.
    mailbox mon2scb;

    // Constructor: binds the interface and mailbox, creates the coverage object.
    function new(virtual apb_interface apb_vif, mailbox mon2scb);
        this.apb_vif = apb_vif;
        this.mon2scb = mon2scb;
        coverage_collector = new();
    endfunction

    // Main task: runs forever, capturing every completed APB transfer.
    task main;
        forever begin
            apb_transaction trans;
            trans = new();

            // Wait for the clock edge where pready is asserted (transfer complete).
            @(posedge apb_vif.clk iff `APB_MON_IF.pready == 1);

            // Capture address and transfer direction.
            trans.paddr  = `APB_MON_IF.paddr;
            trans.pwrite = `APB_MON_IF.pwrite;

            // For writes, record pwdata; for reads, record prdata.
            if (`APB_MON_IF.pwrite == 1) begin
                trans.data = `APB_MON_IF.pwdata;
                $display("%0t [APB-MON] WRITE captured: addr=0x%0h, data=0x%0h",
                         $time(), trans.paddr, trans.data);
            end else begin
                trans.data = `APB_MON_IF.prdata;
                $display("%0t [APB-MON] READ captured: addr=0x%0h, data=0x%0h",
                         $time(), trans.paddr, trans.data);
            end

            // Forward the transaction to the scoreboard and sample coverage.
            mon2scb.put(trans);
            coverage_collector.sample(trans);
        end
    endtask

endclass

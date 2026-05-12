// NOTE: This file is an early draft and is NOT included in the build.
// The real implementation of collect_apb_transactions is a task inside
// scoreboard.sv. This stub is kept only for reference.
function void collect_apb_transactions();
    apb_trans_t apb_trans;  // Placeholder: transaction object or struct.
    forever begin
        apb_mon2scb.get(apb_trans);  // Get the APB transaction from the mailbox.
        // Real logic lives in scoreboard.sv (register mirroring + read-back checks).
    end
endfunction

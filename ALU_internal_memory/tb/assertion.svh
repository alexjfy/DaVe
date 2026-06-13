// Module name: assertion
// HDL        : SystemVerilog Assertions (SVA)
// Description: Protocol assertions for the APB interface to the DUT.
//              Defines the APB phase sequences (idle, setup, access-wait,
//              access-last), generic "not X/Z" and "stable during transfer"
//              properties, and the assertions that check them. Also asserts
//              that pslverr is raised on an invalid address, that afvip_intr
//              fires within 10 cycles of the trigger, and that the protocol
//              state-machine only moves between legal phases.

// Sequences
// APB phase definitions. One per protocol state so the properties below can
// reason about transitions without repeating the raw signal combinations.
sequence idle_phase ;
   !psel ;
endsequence
sequence setup_phase ;
   psel && !penable ;
endsequence
sequence access_phase_wait ;
   psel && penable && !pready ;
endsequence
sequence access_phase_last ;
   psel && penable && pready ;
endsequence
sequence error_ctrl_opcode;
   paddr % 4 != 0 || paddr > 'h8c ;
endsequence
sequence afvip_intr_ver;
   paddr == 'h8c && pwdata ==1;
endsequence

// Properties
// Generic "signal is not X/Z" checks. The APB spec only formally requires
// psel to be valid at all times, but we check the rest as sanity checks.
property pr_generic_not_unknown_psel ;
   @(posedge clk) disable iff(!reset_n)
      !$isunknown(psel) ;
endproperty
property pr_generic_not_unknown_pwrite ;
   @(posedge clk) disable iff(!reset_n)
      !$isunknown(pwrite) ;
endproperty
property pr_generic_not_unknown_pready ;
   @(posedge clk) disable iff(!reset_n)
      !$isunknown(pready) ;
endproperty
property pr_generic_not_unknown_penable ;
   @(posedge clk) disable iff(!reset_n)
      !$isunknown(penable) ;
endproperty
property pr_generic_not_unknown_prdata ;
   @(posedge clk) disable iff(!reset_n)
      !$isunknown(prdata) ;
endproperty
property pr_generic_not_unknown_pwdata ;
   @(posedge clk) disable iff(!reset_n)
      !$isunknown(pwdata) ;
endproperty
property pr_generic_not_unknown_paddr ;
   @(posedge clk) disable iff(!reset_n)
      !$isunknown(paddr) ;
endproperty
// "Signal is stable during a transfer" checks. If a signal changes, the bus
// must currently be in idle or setup phase (i.e. the transfer already ended).
property pr_generic_stable_paddr ;
   @(posedge clk) disable iff(!reset_n)
      !$stable(paddr) |-> setup_phase or idle_phase ;
endproperty
property pr_generic_stable_pwrite ;
   @(posedge clk) disable iff(!reset_n)
      !$stable(pwrite) |-> setup_phase or idle_phase ;
endproperty
property pr_generic_stable_pslverr;
   @(posedge clk) disable iff(!reset_n)
      !$stable(pslverr) |-> setup_phase or idle_phase ;
endproperty
// Same idea for pwdata, but only applies in WRITE transfers (pwrite=1).
property pwdata_in_wr_transfer ;
   @(posedge clk) disable iff(!reset_n)
      !$stable(pwdata) |-> (!pwrite) or (setup_phase or idle_phase) ;
endproperty
// penable and psel drive the phase definitions themselves, so they need
// their own checks instead of using the phase sequences.
property penable_in_transfer ;
   @(posedge clk) disable iff(!reset_n)
      $fell(penable) |-> idle_phase or ($past(penable) && $past(pready)) ;
endproperty
// psel is only allowed to drop after the transfer completes (pready=1).
property psel_in_transfer ;
   @(posedge clk) disable iff(!reset_n)
      !psel && $past(psel) |-> $past(penable) && $past(pready) ; // The antecedent is NOT $fell because 'X'->'0' also triggers $fell
endproperty
// pslverr must be high when the address is not word-aligned or above 'h8c.
property pslverr_error_ctrl ;
   @(posedge clk) disable iff(!reset_n)
       error_ctrl_opcode |-> pslverr ;
endproperty
// afvip_intr must go high within 1..10 cycles after the triggering write.
property afvip_intr_ctrl ;
   @(posedge clk) disable iff(!reset_n)
      afvip_intr_ver |-> ##[1:10](afvip_intr) ; // The antecedent is NOT $fell because 'X'->'0' also triggers $fell
endproperty
// When reset drops low, the design must eventually come out of reset.
property reset_active_low ;
   @(posedge clk)
   !reset_n |=> ##[0:$] $rose(reset_n);
endproperty

// Operating states. Legal next-phase transitions of the APB state machine.
property idle_state ;
   @(posedge clk) disable iff(!reset_n)
      idle_phase |=> idle_phase or setup_phase ;
endproperty
property setup_state ;
   @(posedge clk) disable iff(!reset_n)
      setup_phase |=> access_phase_wait or access_phase_last ;
endproperty
property access_wait_state ;
   @(posedge clk) disable iff(!reset_n)
      access_phase_wait |=> access_phase_wait or access_phase_last ;
endproperty
property access_last_state ;
   @(posedge clk) disable iff(!reset_n)
      access_phase_last |=> idle_phase or setup_phase ;
endproperty

// Assertions
// Bind each property to an assertion with a descriptive error message.
psel_never_X    : assert property (pr_generic_not_unknown_psel)     else $display("[%0t] Error! psel is unknown (=X/Z)", $time) ;
pwrite_never_X  : assert property (pr_generic_not_unknown_pwrite)   else $display("[%0t] Error! pwrite is unknown (=X/Z)", $time) ;
penable_never_X : assert property (pr_generic_not_unknown_penable)  else $display("[%0t] Error! penable is unknown (=X/Z)", $time) ;
pready_never_X  : assert property (pr_generic_not_unknown_pready )  else $display("[%0t] Error! pready is unknown (=X/Z)", $time) ;
paddr_never_X   : assert property (pr_generic_not_unknown_paddr  )  else $display("[%0t] Error! paddr is unknown (=X/Z)", $time) ;
pwdata_never_X  : assert property (pr_generic_not_unknown_pwdata )  else $display("[%0t] Error! pwdata is unknown (=X/Z)", $time) ;
prdata_never_X  : assert property (pr_generic_not_unknown_prdata )  else $display("[%0t] Error! prdata is unknown (=X/Z)", $time) ;

// Stability checks across a transfer.
asr_paddr_stable_in_transfer     : assert property (pr_generic_stable_paddr )     else $display("[%0t] Error! paddr must not change throughout the transfer", $time) ;
asr_pwrite_stable_in_transfer    : assert property (pr_generic_stable_pwrite)     else $display("[%0t] Error! pwrite must not change throughout the transfer", $time) ;
asr_penable_stable_in_transfer   : assert property (penable_in_transfer)          else $display("[%0t] Error! penable must not change throughout the access phase", $time) ;
asr_psel_stable_in_transfer      : assert property (psel_in_transfer)             else $display("[%0t] Error! psel must not change throughout the transfer", $time) ;
asr_pwdata_stable_in_wr_transfer : assert property (pwdata_in_wr_transfer)        else $display("[%0t] Error! pwdata must not change throughout the write transfer", $time) ;
asr_pslverr_stable_in_transfer   : assert property (pr_generic_stable_pslverr)    else $display("[%0t] Error! pslverr must not change throughout the transfer", $time) ;
asr_pslverr_ctrl                 : assert property (pslverr_error_ctrl )          else $display("[%0t] Error! pslverr must be high when the address is not a multiple of 4 or is greater than 'h8c", $time) ;
asr_afvip_ctrl                   : assert property (afvip_intr_ctrl )             else $display("[%0t] Error! afvip_intr must go high within 10 clock cycles", $time) ;
asr_reset_low                    : assert property (reset_active_low )            else $display("[%0t] Error! the configuration must run on reset low", $time) ;

// Legal transitions between APB operational states.
  Operating_state_idle        : assert property (idle_state)
                                  else $display("[%0t] Error! The transfer must start with the setup phase (psel=1, penable=0).", $time) ;
  Operating_state_setup       : assert property (setup_state)
                                  else $display("[%0t] Error! The setup phase must proceed to access phase (psel=1, penable=1) after 1 clk.", $time) ;
  Operating_state_access_wait : assert property (access_wait_state)
                                  else $display("[%0t] Error! The transfer must stay in access phase (wait state, pready=0) or proceed to finish (pready=1).", $time) ;
  Operating_state_access_last : assert property (access_last_state)
                                  else $display("[%0t] Error! After a transfer finishes it must proceed to IDLE (psel=0) or setup phase (psel=1, penable=0).",  $time) ;

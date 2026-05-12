//-------------------------------------------------------------------------
//						www.verificationguide.com 
//-------------------------------------------------------------------------

//this data type stores data exchanged between generator and driver; the monitor also captures data from the interface, reconstructs it using this type, then processes it
class buttons_transaction;
  //class attributes declaration
  //fields declared with the rand keyword receive random values when randomize() is called
    rand bit button_mod_econ;
    rand bit button_mod_comf;
    rand bit button_mod_thermo;
    rand bit button_child_prot;
  rand int delay;
  rand int hold;  // how many clock cycles we hold the button pressed

constraint delay_c { delay inside {[1:20]}; };
constraint hold_c  { hold inside {[8:15]}; };  // long enough for the counter to finish (econ=4, comf=7)
// press exactly one button per transaction (same as a real user would)
constraint one_button_c { button_mod_econ + button_mod_comf + button_mod_thermo == 1; };
  
  //this function is called after randomize() is applied to objects of this class
  //it displays the randomized attribute values
  function void post_randomize();
    $display("--------- [Trans] post_randomize ------");
    //$display("\t button_mod_thermo  = %0h",button_mod_thermo);
    if(button_mod_econ) $display("\t button_mod_thermo  = %0h\t button_mod_econ = %0h\t button_child_prot = %0h",button_mod_thermo,button_mod_econ,button_child_prot);
    if(button_mod_comf) $display("\t button_mod_thermo  = %0h\t button_mod_comf = %0h",button_mod_thermo,button_mod_comf);
    $display("-----------------------------------------");
  endfunction
  
  //copy operator from one object to another (deep copy)
  function buttons_transaction do_copy();
    buttons_transaction trans;     
    trans = new();
    trans.button_mod_econ  = this.button_mod_econ;
    trans.button_mod_comf = this.button_mod_comf;
    trans.button_mod_thermo = this.button_mod_thermo;
    trans.button_child_prot = this.button_child_prot;
    trans.delay = this.delay;
    trans.hold = this.hold;
    return trans;
  endfunction
endclass
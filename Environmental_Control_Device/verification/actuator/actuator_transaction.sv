`ifndef __actuator_transaction
`define __actuator_transaction

class actuator_transaction extends uvm_sequence_item;

  rand bit Heat_i;
  rand bit AC_i;
  rand bit Blinds_i;
  rand bit Dehumidifier_i;
  
  //add transaction to the UVM database
  `uvm_object_utils_begin(actuator_transaction)
    `uvm_field_int(Heat_i, UVM_ALL_ON)
    `uvm_field_int(AC_i, UVM_ALL_ON)
    `uvm_field_int(Blinds_i, UVM_ALL_ON)
    `uvm_field_int(Dehumidifier_i, UVM_ALL_ON)
  `uvm_object_utils_end
 
  //declare the class constructor;
  function new(string name = "actuator_transaction");
    super.new(name);
  	Heat_i         = 0;
  	AC_i           = 0;
  	Blinds_i       = 0;
  	Dehumidifier_i = 0;
  endfunction
  
  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    bit res;
    actuator_transaction _obj;
    $cast(_obj, rhs);
    res = super.do_compare(_obj, comparer) &
	      Heat_i == _obj.Heat_i &
    	  AC_i == _obj.AC_i &
    	  Blinds_i == _obj.Blinds_i &
    	  Dehumidifier_i == _obj.Dehumidifier_i;
    `uvm_info(get_name(), $sformatf("actuator_transaction::do_compare() result = %0b", res), UVM_DEBUG)
	  return res;
  endfunction

endclass

`endif
`ifndef __semaphore_transaction
`define __semaphore_transaction

//declare an enum to represent the different semaphore states
typedef enum {GREEN, RED} semaphore_state_t;

class semaphore_transaction extends uvm_sequence_item;
  
  rand semaphore_state_t even_semaphore_state;
  rand semaphore_state_t odd_semaphore_state;
  
  //add transaction to the UVM database
  `uvm_object_utils_begin(semaphore_transaction)
    `uvm_field_enum(semaphore_state_t, even_semaphore_state, UVM_ALL_ON)
    `uvm_field_enum(semaphore_state_t, odd_semaphore_state, UVM_ALL_ON)
  `uvm_object_utils_end
  
  //declare the class constructor;
  function new(string name = "semaphore_transaction");
    super.new(name);
  	even_semaphore_state = GREEN;
  	odd_semaphore_state = GREEN;
  endfunction
  
  // //function for comapring 2 transactions
  // virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
  //   bit res;
	//   semaphore_transaction _obj;
	//   $cast(_obj, rhs);
	//   res = super.do_compare(_obj, comparer) &
	//         even_semaphore_state == _obj.even_semaphore_state &
  //   	    odd_semaphore_state == _obj.odd_semaphore_state;
  //   `uvm_info(get_name(), $sformatf("semaphore_transaction::do_compare() result = %0b", res), UVM_LOW)
	//   return res;
  // endfunction
  
endclass : semaphore_transaction

`endif
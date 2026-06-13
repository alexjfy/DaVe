// Module name: reset_sequence
// HDL        : UVM
// Description: Boot-up reset sequence. Drives state=0, then state=1, then
//              toggles reset_n (1 -> 0 -> 1) so the DUT exits reset cleanly
//              before the stimulus starts.
class reset_sequence extends uvm_sequence;

  `uvm_object_utils(reset_sequence)

  function new(string name = "reset_sequence");
    super.new(name);
  endfunction

  reset_item test1;
  
virtual task body();
    begin 
    test1 = reset_item::type_id::create("test1");

    start_item(test1);
      test1.state =0;
    finish_item(test1);
    #50
    start_item(test1);
      test1.state =1;
    finish_item(test1);
    #50
    start_item(test1);
      test1.reset_n =1;
    finish_item(test1);
    #50
    start_item(test1);
      test1.reset_n =0;
    finish_item(test1);
    #50
    start_item(test1);
      test1.reset_n =1;
    finish_item(test1);
    end
  endtask

endclass
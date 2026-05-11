class apb_generator;

  // The class contains two attributes of type "transaction"
  rand apb_transaction trans,tr;

  // repeat_count indicates the number of transactions to be generated
  int  repeat_count;

  // The mailbox data type, which can be seen as a queue structure, represents
  // the "port" through which the generator sends data to the driver
  //mailbox, to generate and send the packet to driver
  mailbox gen2driv;

  // Event declaration
  event ended;

  //constructor
  function new(mailbox gen2driv,event ended);
    //getting the mailbox handle from env, in order to share the transaction packet between the generator and driver, the same mailbox is shared between both.
    this.gen2driv = gen2driv;
    this.ended    = ended;
    trans = new();
  endfunction

  // main() is used for random test scenarios - generates repeat_count randomized transactions
  // and pushes them to the mailbox for the driver to consume.
  // Directed tests bypass this and call write_register / read_register instead.
  task main();
    $display("[Gen] starting random generation, repeat_count=%0d", repeat_count);
    repeat(repeat_count) begin
    	if( !trans.randomize() )
          $fatal(1, "Gen:: trans randomization failed");
    	tr = trans.do_copy();
    	gen2driv.put(tr);
    end
    $display("[Gen] random generation finished (%0d transactions sent)", repeat_count);
    // Signal the end of data transmission by the generator
    -> ended;
  endtask

  // Directed write: bypasses randomization and pushes a specific write transaction
  // to the mailbox. Used by directed tests that need deterministic stimulus.
  task write_register (bit [1:0] address1, bit [7:0] data1);
    trans.address = address1;
    trans.data = data1;
    trans.write_enable = 1;
    trans.delay = 0;
    tr = trans.do_copy();
    gen2driv.put(tr);
    $display("[Gen] write register addr=0x%0h data=0x%0h", address1, data1);
  endtask

  // Directed read: bypasses randomization and pushes a specific read transaction
  task read_register (bit [1:0] address1);
    trans.address = address1;
    trans.write_enable = 0;
    trans.delay = 0;
    tr = trans.do_copy();
    gen2driv.put(tr);
    $display("[Gen] read register addr=0x%0h", address1);
  endtask
endclass

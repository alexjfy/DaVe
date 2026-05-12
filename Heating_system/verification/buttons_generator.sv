//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
class buttons_generator;
  
  //the class contains two attributes of type "transaction"
  rand buttons_transaction trans,tr;

  //repeat_count indicates the number of transactions to be generated
  int  repeat_count;

  //the mailbox data type (a queue-like structure) is the "port" through which the generator sends data to the driver
  //mailbox, to generate and send the packet to driver
  mailbox gen2driv;

  //event declaration
  event ended;
  
  //constructor
  function new(mailbox gen2driv,event ended);
    //getting the mailbox handle from env, in order to share the transaction packet between the generator and driver, the same mailbox is shared between both.
    this.gen2driv = gen2driv;
    this.ended    = ended;
    trans = new();
  endfunction
  
  //the generator randomizes and transmits transaction contents through the mailbox "port" (count equals repeat_count)
  //main task, generates(create and randomizes) the repeat_count number of transaction packets and puts into mailbox
  task main();
    repeat(repeat_count) begin
    	if( !trans.randomize() )
          $fatal("Gen:: trans randomization failed");
    	tr = trans.do_copy();
    	gen2driv.put(tr);
    end
    //signal the end of data generation
    -> ended;
  endtask
  
endclass
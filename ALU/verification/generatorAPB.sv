class generatorAPB;

     //The class contains two attributes of type "transaction"
     rand transactionAPB trans,tr;

     //repeat_count indicates the number of transactions to be generated
     int repeat_count;

     //The mailbox data type, which can be seen as a queue structure, represents the "port" through which the generator sends data to the driver
     //mailbox, to generate and send the packet to driver
     mailbox gen2driv;

     //Event declaration
     event ended;


     //constructor
  function new(mailbox gen2driv,event ended);
         //getting the mailbox handle from env, in order to share the transaction packet between the generator and driver, the same mailbox is shared between both.
         this.gen2driv = gen2driv;
         this.ended = ended;
         trans = new();
     endfunction

     //The generator randomizes and sends transaction contents through the mailbox "port" (the number of transactions equals repeat_count)
     //main task, generates(create and randomizes) the repeat_count number of transaction packets and puts into mailbox
     task main();
         repeat(repeat_count) begin
           if( !trans.randomize() )
                     $fatal("Gen:: trans randomization failed");
           tr = trans.do_copyAPB();
           gen2driv.put(tr);
         end
//          Signal the end of data transmission by the generator
         -> ended;
     endtask

  task generate_write( bit [31:0] dat, bit [4:0] adr );
    if(!trans.randomize() with {addr == adr; write == 1; data == dat; delay > 0; delay < 100;} )
$fatal("Gen::trans randomization failed");
//        	trans.data = data;
       tr = trans.do_copyAPB();
//        	trans.addr = addr;
//         trans.write = 1;
       gen2driv.put(tr);
     endtask

     task generate_read( bit [4:0] adr );
       if(!trans.randomize() with {addr == adr; write == 0; delay > 0; delay < 100;} )
$fatal("Gen::trans randomization failed");
       tr = trans.do_copyAPB();
       gen2driv.put(tr);
     endtask
endclass
class apb_generator#(int AW=32, DW=32);

  //the class contains two attributes of type "transaction"
  rand apb_transaction#(AW,DW) trans,tr;

  //repeat_count indicates the number of transactions to be generated
  int  repeat_count;

  //the mailbox data type, which can be seen as a queue structure, represents the "port" through which the generator sends data to the driver
  //mailbox, to generate and send the packet to driver
  mailbox gen2driv;

  //flag to signal that the generator has finished
  bit gen_done;

  //constructor
  function new(mailbox gen2driv);
    //getting the mailbox handle from env, in order to share the transaction packet between the generator and driver, the same mailbox is shared between both.
    this.gen2driv = gen2driv;
    this.gen_done    = 0;
    trans = new();
  endfunction

  //the generator randomizes and sends through the mailbox "port" the transaction contents (whose count equals repeat_count)
  //main task, generates (create and randomizes) the repeat_count number of transaction packets and puts into mailbox
  task main();
    repeat(repeat_count) begin
    	if( !trans.randomize())
          $fatal("Gen:: trans randomization failed");
    	tr = trans.do_copy();
    	gen2driv.put(tr);
    end
    //signal that the generator has finished sending data
    gen_done = 1;
  endtask


  task write_register(bit [AW-1:0] add, bit [DW-1:0] dat);
    if(!trans.randomize() with {data == dat; addr == add; kind == APB_WRITE;}) begin
          $fatal("Gen:: trans randomization failed");
    end
    tr = trans.do_copy();
    	gen2driv.put(tr);
  endtask


   task write_register_random(bit [AW-1:0] add);
     if(!trans.randomize() with {data < 'hFF; addr == add; kind == APB_WRITE;}) begin
          $fatal("Gen:: trans randomization failed");
    end
    tr = trans.do_copy();
    	gen2driv.put(tr);
  endtask


  task read_register(bit [AW-1:0] add);
    if( !trans.randomize() with {addr == add; kind == APB_READ;})
          $fatal("Gen:: trans randomization failed");
    tr = trans.do_copy();
    	gen2driv.put(tr);
  endtask

  task write_all_priority_reg() ;
    bit [3:0] generated_values[$];//[4,6,3,7,1,8] - systemVerilog queue
    bit [3:0] currently_generated_priority;
	bit value_was_already_generated = 0;
//iterate through each interrupt
    for (int i =1; i<=8; i++) begin
		currently_generated_priority = $urandom_range(1,8);
		value_was_already_generated = 0;  // assume the value in currently_generated_priority has not been generated before
		for(int j = 0; j< generated_values.size();j++) //scan the memory to check if the currently generated priority was already assigned to another interrupt
      		if ( currently_generated_priority == generated_values[j])
				value_was_already_generated = 1;
			if (value_was_already_generated == 1)
     			i--; //for each already-existing priority value in memory, we need to generate a new value;
			else
			begin
			generated_values.push_back(currently_generated_priority);//added the generated value to the queue
			write_register(i, currently_generated_priority);
			end
	end
  endtask


endclass
module apb_dummy
  #(  
  parameter ADDR_WIDTH = 6,
  parameter DATA_WIDTH = 32
  )
  (
    input clk,
    input reset,
    
    //APB signals 
    output reg  [ADDR_WIDTH - 1:0]  paddr, 
    output reg  [DATA_WIDTH - 1:0]  pwdata, 
    input	 	[DATA_WIDTH - 1:0]	prdata,
    output reg             			pwrite, 
    output reg             			penable, 
    output reg            			psel, 
    input            				pready, 
    input            				pslverr
    
  ); 
  
  task apb_command;
    input	[ADDR_WIDTH - 1:0] 	paddr_t;
    input 	[DATA_WIDTH - 1:0] 	pwdata_t;
    input 						pwrite_t;
    input 						penable_t;
    input 						psel_t;
    
    begin
      paddr <= paddr_t;
      pwdata <= pwdata_t;
      pwrite <= pwrite_t;
      penable <= penable_t;
      psel <= psel_t;
      @(posedge clk);
      penable <= 1'b1;
      while(~pready) @(posedge clk);
      @(posedge clk);
      paddr <= 'hx;
      pwdata <= 'hx;
      pwrite <= 'bx;
      penable <= 'bx;
      psel <= 'b0;
      repeat(20) @(posedge clk);
    end
    
  endtask
  
  initial begin

  paddr     <= 1'bx;	
  pwdata    <= 1'bx;
  pwrite    <= 1'bx;
  penable 	<= 1'bx;
  psel     	<= 1'bx;

    @(negedge reset);	// active reset
  	paddr         <= 'h0;	
  	pwdata     	<= 'h0 ;
  	pwrite      	<= 1'b0;
 	penable 		<= 1'b0;
 	psel	     	<= 1'b0;
    @(posedge reset);	// inactive reset
  	@(posedge clk);		// first active edge clock after reset
  
    //write to enable_interrupts
    apb_command('h00, 'hFF, 1'b1, 1'b0, 1'b1); //write
    //write to priority registers
    apb_command('h01, 'h2, 1'b1, 1'b0, 1'b1); //write
    apb_command('h02, 'h6, 1'b1, 1'b0, 1'b1); //write
    apb_command('h03, 'h1, 1'b1, 1'b0, 1'b1); //write
    apb_command('h04, 'h4, 1'b1, 1'b0, 1'b1); //write
    apb_command('h05, 'h3, 1'b1, 1'b0, 1'b1); //write
    apb_command('h06, 'h5, 1'b1, 1'b0, 1'b1); //write
    apb_command('h07, 'h8, 1'b1, 1'b0, 1'b1); //write
    apb_command('h08, 'h7, 1'b1, 1'b0, 1'b1); //write
    //write to external interrupts
    apb_command('h09, 'hFF, 1'b1, 1'b0, 1'b1); //write
    
    //apb_command('h02, 'h3, 1'b1, 1'b0, 1'b1); //write
  	#7000				
    
    //apb_command('h00, 'h3C, 1'b1, 1'b0, 1'b1); //write
    //write to priority registers
    //apb_command('h01, 'h1, 1'b1, 1'b0, 1'b1); //write
    //apb_command('h02, 'h2, 1'b1, 1'b0, 1'b1); //write
    //apb_command('h03, 'h3, 1'b1, 1'b0, 1'b1); //write
    //apb_command('h04, 'h4, 1'b1, 1'b0, 1'b1); //write
    //apb_command('h05, 'h5, 1'b1, 1'b0, 1'b1); //write
    //apb_command('h06, 'h6, 1'b1, 1'b0, 1'b1); //write
    //apb_command('h07, 'h7, 1'b1, 1'b0, 1'b1); //write
    //apb_command('h08, 'h8, 1'b1, 1'b0, 1'b1); //write
    //write to external interrupts
    //apb_command('h09, 'hFF, 1'b1, 1'b0, 1'b1); //write
    
    //#6000
    
  	$display("Simulation done!!!");
    $stop();
  
end

endmodule
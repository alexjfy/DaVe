														   
				  
module data 
#(parameter WIDTH = 'd8)
  (
  input             clk,
  input             reset,
  input             button,
  input [WIDTH-1:0] sensor,
  input             valid,
  input             done,
  output reg [1:0]  light_level,
  input             s_off,
  input             s_on0,
  input             s_on1,
  input             s_on2,
  input             s_auto, 
  input             s_disable,
  output reg        short_push,
  output reg        long_push
);
  
  reg [WIDTH-1:0] val_sensor = 0;
  reg [5:0]       counter;
  reg             button_last;
  
  always @(posedge clk or negedge reset) begin
    if(reset == 0)
		val_sensor <= 'b0;
	else				
							
      if(valid && s_auto)
        val_sensor <= sensor;
  end
  
  always @(posedge clk) begin
    if(reset == 1) begin
	  if(s_auto && done)begin
	    light_level <= 3- (val_sensor>>6);
		$display($time());
		$display("DUT-ul: light level: ");
		$display(light_level);
		$display("DUT-ul: val_sensor: ");
		$display(val_sensor);
		$display("DUT-ul: val_sensor>>6: ");
		$display(val_sensor>>6);
		end
	  else if(s_auto)
		  light_level <=2'b00;
	  else if(s_off || s_disable)
          light_level <= 2'b00;
      else if(s_on0)
          light_level <= 2'b01;
      else if(s_on1)
          light_level <= 2'b10;
      else if(s_on2)
          light_level <= 2'b11;
	   
    end
  end
  
  
  always @(posedge clk) begin
    if(reset == 1) begin
      if(button_last == 1 && button == 0)begin
        counter <= 'b0;
        short_push <= 'b0;
        long_push <= 'b0;
      end
      else if(button_last == 0 && button == 0)begin
        if(counter < 19)
          counter <= counter + 1;
        else if(counter == 19)begin
          long_push <= 'b1;
          counter <= counter + 1;
        end
        else 
          long_push <= 'b0;
      end
      else if(button_last == 0 && button == 1)begin
        if(counter < 19)
          short_push <= 'b1;
      end
      else 
        short_push <= 'b0;
    end
  end
  
  always @(posedge clk) begin
    if(reset == 1)
    	button_last <= button;
  end
  
  always @(negedge reset) begin
    if(reset == 0)begin
      light_level <= 'b0;
      short_push <= 'b0;
      long_push <= 'b0;
      counter <= 'b0;
      button_last <= 'b1;
    end
  end
endmodule
module key_detector (clk, KEY, key_press);
/*
Module detects a press of the key and filters out
any duration in which the key is pressed so it only
returns a true value in key_press of one edge of the
clock. This is done with a DFF, the detector looks 
for the one posedge of the clock in which D is 0 and
Q is 1.
*/
	input clk;
	input [1:0] KEY;
	output key_press;
	
	reg key_press_r;
	reg Q;
	
	initial begin
		key_press_r = 1'b0;
	end
	
	always @ (posedge clk)
	begin
		Q <= KEY[0];
		key_press_r <= ~KEY[0] & Q;
	end
	
	assign key_press = key_press_r;
	
endmodule
	
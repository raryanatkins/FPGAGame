/*
This module takes the output of the smoothing filter for x and y
and sets these values to the minimum if they are below minimum and
sets to maximum if greater than maximum, otherwise the inputted 
value is output normally
*/
module scale_and_saturate (
	input 		  clk,
	input  [15:0] smoothing_filter_out_x,
	input  [15:0] smoothing_filter_out_y,
	output [9:0]  pixel_x_sat,
	output [8:0]  pixel_y_sat
);

	reg [15:0] pixel_x;
	reg [15:0] pixel_y;
	
	always @ (posedge clk)
	begin
		pixel_x = smoothing_filter_out_x + 16'd320;		// Add 320 to find center x pixel of shape
		pixel_y = smoothing_filter_out_y + 16'd240;		// Add 240 for y
		
		if (pixel_x > 16'd631)
			pixel_x <= 16'd631;				// Set center x pixel to upper bound if it exceeds bound
		else if (pixel_x < 16'd8)
			pixel_x <= 16'd8;					// Similar for lower bound
		else
			pixel_x <= pixel_x;				// Shown for clarity, retain x pixel when within bounds
			
		// Specified arbitrary range for y values since tilting the board all the way up gives
		// data_y + 320 a value past 16'h0000, this goes back to the negative range something
		// near and below 16'hffff
		if (pixel_y > 16'd471 && pixel_y < 16'd500)
			pixel_y <= 16'd471;				// Similar for y bounds
		else if (pixel_y < 16'd8 || pixel_y > 16'd500)
			pixel_y <= 16'd8;
		else
			pixel_y <= pixel_y;
	end
	
	assign pixel_x_sat = pixel_x[9:0];
	assign pixel_y_sat = pixel_y[8:0];
	
endmodule
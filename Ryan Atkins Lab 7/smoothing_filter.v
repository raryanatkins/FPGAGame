/*
This module takes the average of a specified number of recent accelerometer
samples. The number of samples depends upon switches 1-0. This module effectively
smooths the location of the spaceship by preventing the otherwise jerky behavior
*/
module smoothing_filter (
	input  [1:0]  SW,
	input 	 	  data_update,
	input  [15:0] data_x,
	input  [15:0] data_y,
	output [15:0] smoothing_filter_out_x,
	output [15:0] smoothing_filter_out_y
	);
	
	reg [255:0]  shift_reg_x, shift_reg_y;
	reg [19:0]	 sum_x, sum_y;

	
	always @ (posedge data_update)
	begin
		shift_reg_x = shift_reg_x << 5'b10000; // Shift left by 16 to lose oldest sample
		shift_reg_x [15:0] = ~data_x;				// Replace lowest 16 bits with newest sample
		// Note: data_x is inverted to invert the "controls", tilting the board left moves the shape to the left and vice versa
			
		shift_reg_y = shift_reg_y << 5'b10000;	// Repeat for y
		shift_reg_y [15:0] = data_y;

/*
All of the logic below is just sign extending data_x and data_y. After case 00, data_x and data_y are stored in a shift register
so that the previous 16 samples are held. In cases 01, 10, and 11, the sign is extended directly from the shift register and then
either 2, 4, or 16 samples are summed before being shifted by 1, 2, or 4 to effectively divide by 2, 4, or 16 respectively. 
The result is then sent to the higher level module through smoothing_filter_out wires
*/
		case(SW)
			
			2'b00: begin
				sum_x = {data_x[15], data_x[15], data_x[15], data_x[15], data_x};	// No smoothing
					
				sum_y = {data_y[15], data_y[15], data_y[15], data_y[15], data_y};
			end
				
			2'b01: begin
				sum_x = {shift_reg_x[15], shift_reg_x[15], shift_reg_x[15], shift_reg_x[15], shift_reg_x [15:0]} + {shift_reg_x[31], shift_reg_x[31], shift_reg_x[31], shift_reg_x[31], shift_reg_x[31:16]};
				sum_x = sum_x >> 1'b1;		// Shift right by 1 to divide by 2
					
				sum_y = {shift_reg_y[15], shift_reg_y[15], shift_reg_y[15], shift_reg_y[15], shift_reg_y [15:0]} + {shift_reg_y[31], shift_reg_y[31], shift_reg_y[31], shift_reg_y[31], shift_reg_y[31:16]};
				sum_y = sum_y >> 1'b1;
			end
				
			2'b10: begin
				sum_x = {shift_reg_x[15], shift_reg_x[15], shift_reg_x[15], shift_reg_x[15], shift_reg_x [15:0]} + {shift_reg_x[31], shift_reg_x[31], shift_reg_x[31], shift_reg_x[31], shift_reg_x[31:16]} + {shift_reg_x[47], shift_reg_x[47], shift_reg_x[47], shift_reg_x[47], shift_reg_x[47:32]} + {shift_reg_x[63], shift_reg_x[63], shift_reg_x[63], shift_reg_x[63], shift_reg_x[63:48]};
				sum_x = sum_x >> 2'b10;		// Shift right by 2 to divide by 4
					
				sum_y = {shift_reg_y[15], shift_reg_y[15], shift_reg_y[15], shift_reg_y[15], shift_reg_y [15:0]} + {shift_reg_y[31], shift_reg_y[31], shift_reg_y[31], shift_reg_y[31], shift_reg_y[31:16]} + {shift_reg_y[47], shift_reg_y[47], shift_reg_y[47], shift_reg_y[47], shift_reg_y[47:32]} + {shift_reg_y[63], shift_reg_y[63], shift_reg_y[63], shift_reg_y[63], shift_reg_y[63:48]};
				sum_y = sum_y >> 2'b10;
			end
				
			2'b11: begin
				sum_x = {shift_reg_x[15], shift_reg_x[15], shift_reg_x[15], shift_reg_x[15], shift_reg_x [15:0]} + {shift_reg_x[31], shift_reg_x[31], shift_reg_x[31], shift_reg_x[31], shift_reg_x[31:16]} + {shift_reg_x[47], shift_reg_x[47], shift_reg_x[47], shift_reg_x[47], shift_reg_x[47:32]} + {shift_reg_x[63], shift_reg_x[63], shift_reg_x[63], shift_reg_x[63], shift_reg_x[63:48]} + {shift_reg_x[79], shift_reg_x[79], shift_reg_x[79], shift_reg_x[79], shift_reg_x[79:64]} + {shift_reg_x[95], shift_reg_x[95], shift_reg_x[95], shift_reg_x[95], shift_reg_x[95:80]} + {shift_reg_x[111], shift_reg_x[111], shift_reg_x[111], shift_reg_x[111], shift_reg_x[111:96]} + {shift_reg_x[127], shift_reg_x[127], shift_reg_x[127], shift_reg_x[127], shift_reg_x[127:112]} + {shift_reg_x[143], shift_reg_x[143], shift_reg_x[143], shift_reg_x[143], shift_reg_x[143:128]} + {shift_reg_x[159], shift_reg_x[159], shift_reg_x[159], shift_reg_x[159], shift_reg_x[159:144]} + {shift_reg_x[175], shift_reg_x[175], shift_reg_x[175], shift_reg_x[175], shift_reg_x[175:160]} + {shift_reg_x[191], shift_reg_x[191], shift_reg_x[191], shift_reg_x[191], shift_reg_x[191:176]} + {shift_reg_x[207], shift_reg_x[207], shift_reg_x[207], shift_reg_x[207], shift_reg_x[207:192]} + {shift_reg_x[223], shift_reg_x[223], shift_reg_x[223], shift_reg_x[223], shift_reg_x[223:208]} + {shift_reg_x[239], shift_reg_x[239], shift_reg_x[239], shift_reg_x[239], shift_reg_x[239:224]} + {shift_reg_x[255], shift_reg_x[255], shift_reg_x[255], shift_reg_x[255], shift_reg_x[255:240]};
				sum_x = sum_x >> 3'b100;	// Shift right by 4 to divide by 16
					
				sum_y = {shift_reg_y[15], shift_reg_y[15], shift_reg_y[15], shift_reg_y[15], shift_reg_y [15:0]} + {shift_reg_y[31], shift_reg_y[31], shift_reg_y[31], shift_reg_y[31], shift_reg_y[31:16]} + {shift_reg_y[47], shift_reg_y[47], shift_reg_y[47], shift_reg_y[47], shift_reg_y[47:32]} + {shift_reg_y[63], shift_reg_y[63], shift_reg_y[63], shift_reg_y[63], shift_reg_y[63:48]} + {shift_reg_y[79], shift_reg_y[79], shift_reg_y[79], shift_reg_y[79], shift_reg_y[79:64]} + {shift_reg_y[95], shift_reg_y[95], shift_reg_y[95], shift_reg_y[95], shift_reg_y[95:80]} + {shift_reg_y[111], shift_reg_y[111], shift_reg_y[111], shift_reg_y[111], shift_reg_y[111:96]} + {shift_reg_y[127], shift_reg_y[127], shift_reg_y[127], shift_reg_y[127], shift_reg_y[127:112]} + {shift_reg_y[143], shift_reg_y[143], shift_reg_y[143], shift_reg_y[143], shift_reg_y[143:128]} + {shift_reg_y[159], shift_reg_y[159], shift_reg_y[159], shift_reg_y[159], shift_reg_y[159:144]} + {shift_reg_y[175], shift_reg_y[175], shift_reg_y[175], shift_reg_y[175], shift_reg_y[175:160]} + {shift_reg_y[191], shift_reg_y[191], shift_reg_y[191], shift_reg_y[191], shift_reg_y[191:176]} + {shift_reg_y[207], shift_reg_y[207], shift_reg_y[207], shift_reg_y[207], shift_reg_y[207:192]} + {shift_reg_y[223], shift_reg_y[223], shift_reg_y[223], shift_reg_y[223], shift_reg_y[223:208]} + {shift_reg_y[239], shift_reg_y[239], shift_reg_y[239], shift_reg_y[239], shift_reg_y[239:224]} + {shift_reg_y[255], shift_reg_y[255], shift_reg_y[255], shift_reg_y[255], shift_reg_y[255:240]};
				sum_y = sum_y >> 3'b100;
			end
		endcase
	end			// always			
					
	assign smoothing_filter_out_x = sum_x[15:0];
	assign smoothing_filter_out_y = sum_y[15:0];
	
endmodule
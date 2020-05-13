module Lab7_comb (clk, reset_n, start_key, SW, data_update, data_x, data_y, row, col, red, green, blue, score_low, score_mid, score_high);

	input 				clk;
	input 				reset_n;
	input 				start_key;
	input		  [9:0]  SW;
	input 				data_update;
	input  	  [15:0] data_x;
	input  	  [15:0] data_y;
	input  	  [8:0]	row;
	input  	  [9:0]	col;
	output 	  [3:0]	red;
	output 	  [3:0]	green;
	output 	  [3:0]	blue;
	output reg [3:0]  score_low;
	output reg [3:0]  score_mid;
	output reg [3:0]  score_high;
	
//=======================================================
//  REG/WIRE/Parameter declarations
//=======================================================

	reg [3:0] red, green, blue;
	
	reg [8:0] top_bound, bottom_bound;
	reg [9:0] left_bound, right_bound;
	
	wire [15:0] smoothing_filter_out_x;
	wire [15:0] smoothing_filter_out_y;
	wire [9:0] pixel_x_sat;
	wire [8:0] pixel_y_sat;
	
	reg alternate;
	reg enable;
	reg [31:0] count;
	reg [2:0] sec_counter;
	reg [71:0] row_bounds;		// Hold 8 different block heights
	
	wire [1:0] speed;
	wire key_press;
	
	reg [1:0] state;
	wire [8:0] size;
	
	wire [11:0] data_out;
	reg [7:0] addr;
	
	reg [9:0] addr_x;
	reg [8:0] addr_y;
	
	parameter IDLE 		= 2'b00;
	parameter COUNTDOWN  = 2'b01;
	parameter GO 			= 2'b10;
	parameter PAUSE 		= 2'b11;
	
//=======================================================
//  Module Instantiations
//=======================================================

	smoothing_filter smoothing_filter_inst (
		.SW(SW[1:0]),
		.data_update(data_update),
		.data_x(data_x),
		.data_y(data_y),
		.smoothing_filter_out_x(smoothing_filter_out_x),
		.smoothing_filter_out_y(smoothing_filter_out_y)
	);
	
	scale_and_saturate scale_and_saturate_inst (
		.clk(clk),
		.smoothing_filter_out_x(smoothing_filter_out_x),
		.smoothing_filter_out_y(smoothing_filter_out_y),
		.pixel_x_sat(pixel_x_sat),
		.pixel_y_sat(pixel_y_sat)
	);
	
	speed_select speed_select_inst (
		.SW(SW),
		.speed(speed)
	);
	
	block_size block_size_inst (
		.SW(SW),
		.size(size)
	);
	
	key_detector key_detector_inst (
		.clk(clk),
		.KEY(start_key),
		.key_press(key_press)
	);
	
	shape_rom shape_rom_inst (
		.clk(clk),
		.addr(addr),
		.data_out(data_out)
	);

//=======================================================
//  Structural Coding
//=======================================================

	always @ (posedge clk)
	begin
	   // Default calculate the proper bounds for the spaceship 
		// and address for its colors
		left_bound = pixel_x_sat - 10'h008;
		right_bound = pixel_x_sat + 10'h008;
		top_bound = pixel_y_sat - 9'h008;
		bottom_bound = pixel_y_sat + 9'h008;
		addr_y = row - top_bound;
		addr_x = col - left_bound;
		
		count = count + 32'h0000_0001;						// default inc count
		
		// If statements below give enable is true at various frequencies to change speed
		if (count >= 32'h017d_7840 && speed == 2'b00)	// 25 million
			enable = 1'b1;
		else if (count >= 32'h0131_2d00 && speed == 2'b01)	// 20 million
			enable = 1'b1;
		else if (count >= 32'h00e4_e1c0 && speed == 2'b10)	// 15 million
			enable = 1'b1;
		else if (count >= 32'h0098_9680 && speed == 2'b11)	// 10 million
			enable = 1'b1;
			
		if (enable == 1'b1)		// When enable is true, count is reset and alternate is flipped
		begin
			enable = 1'b0;				// Enable only stays true for one cycle at a time
			count = 32'h0000_0000;
			if (state == GO)
			begin
				alternate = ~alternate;
				row_bounds = row_bounds << 4'b1001;		// Shift row_bounds left 9 (shift blocks down)
				case ({data_x[1:0], data_y[1:0]})		// Replace lower 9 bits with new "random" value
					4'b0000: row_bounds[8:0] = 9'd0;
					4'b0001: row_bounds[8:0] = 9'd30;
					4'b0010: row_bounds[8:0] = 9'd60;
					4'b0011: row_bounds[8:0] = 9'd90;
					4'b0100: row_bounds[8:0] = 9'd120;
					4'b0101: row_bounds[8:0] = 9'd150;
					4'b0110: row_bounds[8:0] = 9'd180;
					4'b0111: row_bounds[8:0] = 9'd210;
					4'b1000: row_bounds[8:0] = 9'd240;
					4'b1001: row_bounds[8:0] = 9'd270;
					4'b1010: row_bounds[8:0] = 9'd300;
					4'b1011: row_bounds[8:0] = 9'd330;
					4'b1100: row_bounds[8:0] = 9'd360;
					4'b1101: row_bounds[8:0] = 9'd390;
					4'b1110: row_bounds[8:0] = 9'd420;
					4'b1111: row_bounds[8:0] = 9'd450;
				endcase
				// Score is calculated below, the first if statement prevents score being incremented
				// when the first "invisible" blocks pass the edge of the screen, each time a block
				// passes, the screen, score_low is incremented. Once score_low is 9, it is set to 0
				// on the next increment and score_mid is incremented. Same process for score_high
				if (row_bounds [71:63] != 9'd480 && alternate == 1'b0)
					score_low <= #1 score_low + 4'h1;
				if (score_low == 4'h9)
				begin
					score_low <= #1 4'h0;
					score_mid <= #1 score_mid + 4'h1;
				end
				if (score_mid == 4'h9)
				begin
					score_mid <= #1 4'h0;
					score_high <= #1 score_high + 4'h1;
				end
			end
		end
		
//=======================================================
//  State cases
//=======================================================

		case (state)
//=======================================================
//  IDLE
//  Logic in this state displays the spaceship and waits for key_press
//  to move to the COUNTDOWN state and the scores are all reset to 0
//=======================================================
			IDLE: 
			begin
				if (col >= left_bound && col <= right_bound && row >= top_bound && row <= bottom_bound)
				begin		
					addr = {addr_y[3:0], addr_x[3:0]};
					red = data_out[11:8];
					green = data_out[7:4];
					blue = data_out[3:0];
				end
				else begin
					red = 4'b0000;
					green = 4'b0000;
					blue = 4'b0000;
				end

				if (key_press == 1'b1)
				begin
					state = COUNTDOWN;
					sec_counter = 3'b100;
					score_low <= 4'h0;
					score_mid <= 4'h0;
					score_high <= 4'h0;
				end
			end

//=======================================================
//  COUNTDOWN
//  This state draws 3...2...1... on the screen. The speed of the
//  countdown is dependent upon the settings defined by the speed_select
//  module. The spaceship is also allowed to be drawn but numbers take 
//  precedence. Once the counter has decremented to 0, the state is changed
//  to GO and the first 8 blocks are initialized to be at positions {480, 480 + size}
//  This puts the blocks off the screen so they are "invisible" and do not affect
//  the score
//=======================================================

			COUNTDOWN:
			begin
				if (count == 32'h0000_0000)
					sec_counter = sec_counter - 3'b001;
				case(sec_counter)
					3'b011:				// Draws a 3 to the center of the screen
					begin
						if (col >= 10'd280 && col <= 10'd360 && row >= 9'd264 && row <= 9'd280)
						begin
							red = 4'b1111;
							green = 4'b1111;
							blue = 4'b1111;
						end
						else if (col >= 10'd280 && col <= 10'd360 && row >= 9'd232 && row <= 9'd248)
						begin
							red = 4'b1111;
							green = 4'b1111;
							blue = 4'b1111;
						end
						else if (col >= 10'd280 && col <= 10'd360 && row >= 9'd200 && row <= 9'd216)
						begin
							red = 4'b1111;
							green = 4'b1111;
							blue = 4'b1111;
						end
						else if (col >= 10'd344 && col <= 10'd360 && row >= 9'd200 && row <= 9'd280)
						begin
							red = 4'b1111;
							green = 4'b1111;
							blue = 4'b1111;
						end
						else if (col >= left_bound && col <= right_bound && row >= top_bound && row <= bottom_bound)
						begin		
							addr = {addr_y[3:0], addr_x[3:0]};
							red = data_out[11:8];
							green = data_out[7:4];
							blue = data_out[3:0];
						end
						else begin
							red = 4'b0000;
							green = 4'b0000;
							blue = 4'b0000;
						end
					end
					3'b010:			// Draws a 2
					begin
						if (col >= 10'd280 && col <= 10'd360 && row >= 9'd264 && row <= 9'd280)
						begin
							red = 4'b1111;
							green = 4'b1111;
							blue = 4'b1111;
						end
						else if (col >= 10'd280 && col <= 10'd360 && row >= 9'd232 && row <= 9'd248)
						begin
							red = 4'b1111;
							green = 4'b1111;
							blue = 4'b1111;
						end
						else if (col >= 10'd280 && col <= 10'd360 && row >= 9'd200 && row <= 9'd216)
						begin
							red = 4'b1111;
							green = 4'b1111;
							blue = 4'b1111;
						end
						else if (col >= 10'd344 && col <= 10'd360 && row >= 9'd200 && row <= 9'd248)
						begin
							red = 4'b1111;
							green = 4'b1111;
							blue = 4'b1111;
						end
						else if (col >= 10'd280 && col <= 10'd296 && row >= 9'd248 && row <= 9'd280)
						begin
							red = 4'b1111;
							green = 4'b1111;
							blue = 4'b1111;
						end
						else if (col >= left_bound && col <= right_bound && row >= top_bound && row <= bottom_bound)
						begin		
							addr = {addr_y[3:0], addr_x[3:0]};
							red = data_out[11:8];
							green = data_out[7:4];
							blue = data_out[3:0];
						end
						else begin
							red = 4'b0000;
							green = 4'b0000;
							blue = 4'b0000;
						end
					end
					3'b001:				// Draws a 1
					begin
						if (col >= 10'd312 && col <= 10'd328 && row >= 9'd200 && row <= 9'd280)
						begin
							red = 4'b1111;
							green = 4'b1111;
							blue = 4'b1111;
						end
						else if (col >= left_bound && col <= right_bound && row >= top_bound && row <= bottom_bound)
						begin		
							addr = {addr_y[3:0], addr_x[3:0]};
							red = data_out[11:8];
							green = data_out[7:4];
							blue = data_out[3:0];
						end
						else
						begin
							red = 4'b0000;
							green = 4'b000;
							blue = 4'b0000;
						end
					end
					3'b000: 
					begin
						// Set all blocks initially off the screen/invisible
						row_bounds[8:0]   = 9'd480;
						row_bounds[17:9]  = 9'd480;
						row_bounds[26:18] = 9'd480;
						row_bounds[35:27] = 9'd480;
						row_bounds[44:36] = 9'd480;
						row_bounds[53:45] = 9'd480;
						row_bounds[62:54] = 9'd480;
						row_bounds[71:63] = 9'd480;
						state = GO;
					end
				endcase
			end			// COUNTDOWN state

//=======================================================
//  GO
//  In this state, blocks are drawn at 80 pixel intervals, meaning
//  that there are 8 predefined block locations on the x axis. However,
//  the blocks change y axis and position according to the specified index
//  of row_bounds and the variable size which is defined by switches 7-5
//  in the block_size module. A check is then performed to see if 
//  pixel_x_sat or pixel_y_sat are within the bounds of a block, meaning
//  that there is a collision. On a collision, the state is reset to COUNTDOWN
//  so the blocks disappear and restart. Score is also reset
//=======================================================

			GO:			// Send blocks down the screen (left to right)
			begin
				if (alternate == 1'b0)
				begin
					if (col >= left_bound && col <= right_bound && row >= top_bound && row <= bottom_bound)
					begin		
						addr = {addr_y[3:0], addr_x[3:0]};
						red = data_out[11:8];
						green = data_out[7:4];
						blue = data_out[3:0];
					end
					else if ((col > 10'd559 && col < 10'd639 && row >= row_bounds[8:0] && row <= row_bounds[8:0] + size) || (col > 10'd399 && col < 10'd479 && row >= row_bounds[26:18] && row <= row_bounds[26:18] + size) || (col > 10'd239 && col < 10'd319 && row >= row_bounds[44:36] && row <= row_bounds[44:36] + size) || (col > 10'd079 && col < 10'd159 && row >= row_bounds[62:54] && row <= row_bounds[62:54] + size))
					begin
					if ((pixel_x_sat > 10'd559 && pixel_x_sat < 10'd639 && pixel_y_sat >= row_bounds[8:0] && pixel_y_sat <= row_bounds[8:0] + size) || (pixel_x_sat > 10'd399 && pixel_x_sat < 10'd479 && pixel_y_sat >= row_bounds[26:18] && pixel_y_sat <= row_bounds[26:18] + size) || (pixel_x_sat > 10'd239 && pixel_x_sat < 10'd319 && pixel_y_sat >= row_bounds[44:36] && pixel_y_sat <= row_bounds[44:36] + size) || (pixel_x_sat > 10'd079 && pixel_x_sat < 10'd159 && pixel_y_sat >= row_bounds[62:54] && pixel_y_sat <= row_bounds[62:54] + size))
						begin
							state = COUNTDOWN;
							score_low <= 4'h0;
							score_mid <= 4'h0;
							score_high <= 4'h0;
						end
						red = 4'b1111;
						green = 4'b1111;
						blue = 4'b1111;
					end
					else begin
						red = 4'b0000;
						green = 4'b0000;
						blue = 4'b0000;
					end
				end
				else if (alternate == 1'b1)
				begin
					if (col >= left_bound && col <= right_bound && row >= top_bound && row <= bottom_bound)
					begin		
						addr = {addr_y[3:0], addr_x[3:0]};
						red = data_out[11:8];
						green = data_out[7:4];
						blue = data_out[3:0];
					end
					else if ((col > 10'd479 && col < 10'd559 && row >= row_bounds[17:9] && row <= row_bounds[17:9] + size) || (col > 10'd319 && col < 10'd399 && row >= row_bounds[35:27] && row <= row_bounds[35:27] + size) || (col > 10'd159 && col < 10'd239 && row >= row_bounds[53:45] && row <= row_bounds[53:45] + size) || (col > 10'd000 && col < 10'd79 && row >= row_bounds[71:63] && row <= row_bounds[71:63] + size))
					begin
						if ((pixel_x_sat > 10'd479 && pixel_x_sat < 10'd559 && pixel_y_sat >= row_bounds[17:9] && pixel_y_sat <= row_bounds[17:9] + size) || (pixel_x_sat > 10'd319 && pixel_x_sat < 10'd399 && pixel_y_sat >= row_bounds[35:27] && pixel_y_sat <= row_bounds[35:27] + size) || (pixel_x_sat > 10'd159 && pixel_x_sat < 10'd239 && pixel_y_sat >= row_bounds[53:45] && pixel_y_sat <= row_bounds[53:45] + size) || (pixel_x_sat > 10'd000 && pixel_x_sat < 10'd79 && pixel_y_sat >= row_bounds[71:63] && pixel_y_sat <= row_bounds[71:63] + size))
						begin
							state = COUNTDOWN;
							score_low <= 4'h0;
							score_mid <= 4'h0;
							score_high <= 4'h0;
						end
						red = 4'b1111;
						green = 4'b1111;
						blue = 4'b1111;
					end
					else begin
						red = 4'b0000;
						green = 4'b0000;
						blue = 4'b0000;
					end
				end
				
				if (key_press == 1'b1)
					state = PAUSE;
			end		 // GO state
			
//=======================================================
//  PAUSE
//  This state pauses the game and draws a pause symbol on the top
//  left of the screen. The pause effect happens due to an if statement
//  in the default sequential logic which depends on the state being GO
//  for the row_bounds shift register to shift
//=======================================================

			PAUSE:
			begin
			// Same drawing logic as the GO state to leave blocks on the screen (no movement)
			// With added else if lines to draw a pause symbol on the top left
				if (alternate == 1'b0)
				begin
					if ((col > 10'd559 && col < 10'd639 && row >= row_bounds[8:0] && row <= row_bounds[8:0] + size) || (col > 10'd399 && col < 10'd479 && row >= row_bounds[26:18] && row <= row_bounds[26:18] + size) || (col > 10'd239 && col < 10'd319 && row >= row_bounds[44:36] && row <= row_bounds[44:36] + size) || (col > 10'd079 && col < 10'd159 && row >= row_bounds[62:54] && row <= row_bounds[62:54] + size))
					begin
						blue = 4'b1111;
					end
					else if (col >= 10'd50 && col <= 10'd60 && row >= 9'd20 && row <= 9'd60)
					begin
						red = 4'b1111;
						green = 4'b1111;
						blue = 4'b1111;
					end
					else if (col >= 10'd30 && col <= 10'd40 && row >= 9'd20 && row <= 9'd60)
					begin
						red = 4'b1111;
						green = 4'b1111;
						blue = 4'b1111;
					end
					else if (col >= left_bound && col <= right_bound && row >= top_bound && row <= bottom_bound)
					begin		
						addr = {addr_y[3:0], addr_x[3:0]};
						red = data_out[11:8];
						green = data_out[7:4];
						blue = data_out[3:0];
					end
					else begin
						red = 4'b0000;
						green = 4'b0000;
						blue = 4'b0000;
					end
				end
				else if (alternate == 1'b1)
				begin
					if ((col > 10'd479 && col < 10'd559 && row >= row_bounds[17:9] && row <= row_bounds[17:9] + size) || (col > 10'd319 && col < 10'd399 && row >= row_bounds[35:27] && row <= row_bounds[35:27] + size) || (col > 10'd159 && col < 10'd239 && row >= row_bounds[53:45] && row <= row_bounds[53:45] + size) || (col > 10'd000 && col < 10'd79 && row >= row_bounds[71:63] && row <= row_bounds[71:63] + size))
					begin
						blue = 4'b1111;
					end
					else if (col >= 10'd50 && col <= 10'd60 && row >= 9'd20 && row <= 9'd60)
					begin
						red = 4'b1111;
						green = 4'b1111;
						blue = 4'b1111;
					end
					else if (col >= 10'd30 && col <= 10'd40 && row >= 9'd20 && row <= 9'd60)
					begin
						red = 4'b1111;
						green = 4'b1111;
						blue = 4'b1111;
					end
					else if (col >= left_bound && col <= right_bound && row >= top_bound && row <= bottom_bound)
					begin		
						addr = {addr_y[3:0], addr_x[3:0]};
						red = data_out[11:8];
						green = data_out[7:4];
						blue = data_out[3:0];
					end
					else begin
						red = 4'b0000;
						green = 4'b0000;
						blue = 4'b0000;
					end
				end
				
				if (key_press == 1'b1)		// Unpause
					state = GO;
			end
		endcase
	end		// Always
		

endmodule
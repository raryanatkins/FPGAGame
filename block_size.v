/*
This module determines the size of the block using a multiplexer
which depends upon switches 7:5. It just selects a number to be 
added to the base pixel address of the block. These are in increments
of 30 to make the game progressively more challenging
*/
module block_size (SW, size);
	input [9:0] SW;
	output reg [8:0] size;
	
	always @ (SW)
	begin
		case(SW[7:5])
			3'b000: size = 9'd30;
			3'b001: size = 9'd60;
			3'b010: size = 9'd120;
			3'b011: size = 9'd150;
			3'b100: size = 9'd180;
			3'b101: size = 9'd210;
			3'b110: size = 9'd240;
			3'b111: size = 9'd250;
		endcase
	end
endmodule
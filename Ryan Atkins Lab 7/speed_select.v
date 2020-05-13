/*
This module is just a multiplexer which selects a different
speed that is fed back to the combinational logic module
where it determines the max necessary value of count to enable
a block shift
*/
module speed_select (SW, speed);
	input [9:0] SW;
	output reg [1:0] speed;
	
	always @ (SW)
	begin
		case(SW[9:8])
			2'b00: speed = 2'b00;
			2'b01: speed = 2'b01;
			2'b10: speed = 2'b10;
			2'b11: speed = 2'b11;
		endcase
	end
endmodule
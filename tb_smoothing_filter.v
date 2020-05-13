module tb_smoothing_filter ();

	reg [1:0] SW;
	reg data_update;
	reg [15:0] data_x;
	reg [15:0] data_y;
	wire [15:0] smoothing_filter_out_x;
	wire [15:0] smoothing_filter_out_y;
	
	smoothing_filter UUT (
		.SW(SW),
		.data_update(data_update),
		.data_x(data_x),
		.data_y(data_y),
		.smoothing_filter_out_x(smoothing_filter_out_x),
		.smoothing_filter_out_y(smoothing_filter_out_y)
	);
	
	initial begin
		data_update = 1'b1;
		SW = 2'b00;
		
		//data_x = 16'hfffc;
		data_y = 16'h0001;
		
		data_x = #300 16'h000a;
		
		SW = #500 2'b01;
		
		data_x = #600 16'h00aa;
		data_x = #700 16'h000f;
		
		SW = # 1000 2'b10;
		
		data_x = #1100 16'hfff0;
		data_x = #1200 16'h0006;
		
		data_y = #2000 16'h0008;
		
		SW = #2500 2'b11;
		
		data_x = #2600 16'h749a;
		data_x = #2700 16'h000b;
		data_x = #2800 16'hffff;
		data_y = #2800 16'h0001;
	end
	
	
	always #100 data_update = ~data_update;
	
	always @ SW
		$write("SW = %b \n", SW);
	
	always @ (posedge data_update)
	begin
		 $write("data_x = %d, smoothing_filter_out_x = %d \n", data_x, smoothing_filter_out_x);
		 $write("data_y = %d, smoothing_filter_out_y = %d \n", data_y, smoothing_filter_out_y);
	end
	
endmodule
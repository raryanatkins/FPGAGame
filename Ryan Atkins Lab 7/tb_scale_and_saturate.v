module tb_scale_and_saturate ();
	
	reg clk;
	reg [15:0] smoothing_filter_out_x;
	reg [15:0] smoothing_filter_out_y;
	
	wire [9:0] pixel_x_sat;
	wire [8:0] pixel_y_sat;
	
	scale_and_saturate UUT (
		.clk(clk),
		.smoothing_filter_out_x(smoothing_filter_out_x),
		.smoothing_filter_out_y(smoothing_filter_out_y),
		.pixel_x_sat(pixel_x_sat),
		.pixel_y_sat(pixel_y_sat)
	);
	
	initial begin 
		clk = 1'b0;
		smoothing_filter_out_x = 16'h0000;
		smoothing_filter_out_y = 16'h0000;
		
		#500
		
		smoothing_filter_out_x = 16'h00f9;
		
		#500
		
		smoothing_filter_out_y = 16'hffff;
		
		# 500
		
		smoothing_filter_out_y = 16'd200;
		smoothing_filter_out_x = 16'hfff5;
		
		#500 
		
		smoothing_filter_out_x = 16'hfec0; // -320
		smoothing_filter_out_y = 16'd250;
	end
	
	always clk = #100 ~clk;
	always @ (posedge clk)
		$write("smoothing_filter_out_x = %d, smoothing_filter_out_y = %d, pixel_x_sat = %d, pixel_y_sat = %d \n", smoothing_filter_out_x, smoothing_filter_out_y, pixel_x_sat, pixel_y_sat);
endmodule
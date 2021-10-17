module MtrDrv_tb();

	// DUT stimuli
	reg clk, rst_n;
	reg signed [10:0] lft_spd;
	reg signed [10:0] rght_spd;
	
	// DUT outputs
	wire lftPWM1, lftPWM2, rghtPWM1, rghtPWM2;
	
	// instantiate DUT
	MtrDrv iDUT(.clk(clk),.rst_n(rst_n),.lft_spd(lft_spd),.rght_spd(rght_spd),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),.rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2));
	
	initial begin
		clk = 0;
		rst_n = 0;
		lft_spd = 11'hF0F;
		rght_spd = 11'hF03;
		@(posedge clk)
		@(negedge clk) rst_n = 1;
		
		repeat(500) @(posedge clk);
		$stop;
		
	end
	
	always #5 clk = ~clk;

endmodule
module PWM11_tb();

	// DUT stimuli
	reg clk,rst_n;
	reg [10:0] duty;
	
	// DUT outputs
	wire PWM_sig, PWM_sig_n;
	
	// instantiate DUT
	PWM11 iDUT(.clk(clk),.rst_n(rst_n),.duty(duty),.PWM_sig(PWM_sig),.PWM_sig_n(PWM_sig_n));

	initial begin
		clk = 0;

		@(posedge clk)	// we need to clear the counter after each test or the waveforms will be screwed up.
		rst_n = 0;
		@(negedge clk)
		rst_n = 1;
		duty = 11'h200; // 25% duty cycle
		repeat(25000) @(posedge clk); 		// delay to space out the signals

		@(posedge clk)
		rst_n = 0;
		@(negedge clk)
		rst_n = 1;
		duty = 11'h0; // 0% duty cycle
		repeat(25000) @(posedge clk);

		@(posedge clk)
		rst_n = 0;
		@(negedge clk)
		rst_n = 1;
		duty = 11'h400; // 50% duty cycle
		repeat(25000) @(posedge clk);

		@(posedge clk)
		rst_n = 0;
		@(negedge clk)
		rst_n = 1;
		duty = 11'h600; // 75% duty cycle
		repeat(25000) @(posedge clk);

		$stop;
	end

	always #5 clk = ~clk;

endmodule

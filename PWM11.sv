module PWM11(
	input clk,
	input rst_n,
	input [10:0] duty,
	output reg PWM_sig,
	output reg PWM_sig_n
);

	reg [10:0] cnt;

	// 11 bit counter; ratio of cnt to duty will determine overall duty cycle of PWM_sig
	always_ff @(posedge clk,negedge rst_n)
		if(!rst_n) 
			cnt <= 1'b0;
		else 
			cnt <= cnt + 1'b1;

	// we can't afford to have our output glitch so it will be flopped.
	always_ff @(posedge clk,negedge rst_n) 
		if(!rst_n) 
			PWM_sig <= 1'b0;
		else if(cnt<duty) 
			PWM_sig <= 1'b1;
		else 
			PWM_sig <= 1'b0;
			
	assign PWM_sig_n = ~PWM_sig;

endmodule
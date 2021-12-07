module MtrDrv(
	input clk, rst_n,
	input signed [10:0] lft_spd,
	input signed [10:0] rght_spd,
	output lftPWM1,
	output lftPWM2,
	output rghtPWM1,
	output rghtPWM2
);
	localparam CONST_DUTY = 11'h400;
	wire [10:0] lftDuty, rghtDuty;
	
	assign lftDuty = CONST_DUTY + lft_spd;
	assign rghtDuty = CONST_DUTY + rght_spd;
	
	PWM11 lftPWM11(.clk(clk),.rst_n(rst_n),.duty(lftDuty),.PWM_sig(lftPWM1),.PWM_sig_n(lftPWM2));
	PWM11 rghtPWM11(.clk(clk),.rst_n(rst_n),.duty(rghtDuty),.PWM_sig(rghtPWM1),.PWM_sig_n(rghtPWM2));

endmodule
module I_term(
	input clk, rst_n,
	input err_vld,
	input moving,
	input signed [9:0] err_sat,
	output [8:0] I_term
);
	wire ov;
	wire signed [14:0] err_sat_ext, err_int_accum, err_chk_integrator, nxt_integrator;
	reg signed [14:0] integrator;
	
	// sign-extend 10-bit error to 15 bits, then accumulate.
	assign err_sat_ext = {{5{err_sat[9]}},err_sat};
	assign err_int_accum = err_sat_ext + integrator;
	
	// if MSBs of operands match, MSB of addition result should also match MSB of operand. otherwise overflow.
	assign ov = (~(integrator[14]^err_sat_ext[14])) && (err_int_accum[14] != integrator[14]);
	
	// error is accumulated if valid. otherwise it is frozen at previous value.
	assign err_chk_integrator = (~ov && err_vld) ? err_int_accum : integrator;
	
	// clear integrator if not moving.
	assign nxt_integrator = moving ? err_chk_integrator : 15'h0000;
	
	// infer integrator flop
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			integrator <= 15'h0000;
		else
			integrator <= nxt_integrator;
	end
	
	assign I_term = integrator[14:6];

endmodule
module SDiv(
	input clk, rst_n,
	input go,
	input signed [15:0] dividend,
	input signed [15:0] divisor,
	output logic signed [15:0] quotient,
	output logic rdy
);
	typedef enum reg [1:0] { IDLE,COMPUTE,END } state_t;
	state_t state, nxt_state;
	logic init, set_rdy;
	logic [15:0] abs_dividend, abs_divisor, nxt_A, nxt_B, A, B, AB_diff;
	logic negate_res;
	logic signed [15:0] nxt_quotient;
	logic [1:0] q_sel;

	// state register
	always_ff @(posedge clk,negedge rst_n) begin
		if (!rst_n) 
			state <= IDLE;
		else 
			state <= nxt_state;
	end

	// state transition and output logic
	always_comb begin

		// default outputs to avoid latches
		nxt_state = state;
		init = 0;
		set_rdy = 0;
		q_sel = 2'b11;
	
		case(state)
			IDLE: begin
				if(go) begin
					nxt_state = COMPUTE;
					init = 1;
					q_sel = 2'b00;
				end
			end

			COMPUTE: begin
				// keep incrementing until A-B goes negative
				if(!AB_diff[15]) begin
					q_sel = 2'b01;
					nxt_state = COMPUTE;
				
				// invert or keep current result
				end else begin
					nxt_state = END;
					if(negate_res)
						q_sel = 2'b10;
					else
						q_sel = 2'b11;
				end
			end

			default: begin // END
				nxt_state = IDLE;
				set_rdy = 1;
				q_sel = 2'b11;
			end

		endcase

	end // end state transition and output logic
	
	// datapath logic for absolute val
	assign abs_dividend = dividend[15] ? (~dividend)+1 : dividend;
	assign abs_divisor = divisor[15] ? (~divisor)+1 : divisor;
	
	assign nxt_A = init ? abs_dividend : AB_diff;
	assign nxt_B = init ? abs_divisor : B;
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			A <= 0;
			B <= 0;
		end else begin
			A <= nxt_A;
			B <= nxt_B;
		end
	end
	
	assign AB_diff = A - B; // end abs val datapath
	
	// datapath logic for result
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			negate_res <= 0;
		else if (init)
			negate_res <= dividend[15] ^ divisor[15];
	end
	
	// 4:1 mux
	always_comb begin
		case(q_sel)
			2'b00: nxt_quotient = 16'h0000;
			2'b01: nxt_quotient = quotient + 1;
			2'b10: nxt_quotient = (~quotient) + 1;
			2'b11: nxt_quotient = quotient;
		endcase
	end
	
	// rdy SR flop
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			rdy <= 0;
		else if(init)
			rdy <= 0;
		else if(set_rdy)
			rdy <= 1;
		// else hold rdy
	end
	
	// result flop
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			quotient <= 0;
		else
			quotient <= nxt_quotient;
	end

endmodule
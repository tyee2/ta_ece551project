module SPI_mnrch(
	input 				clk, rst_n,
	input 				wrt,
	input [15:0]		wt_data,
	input 				MISO,
	output logic		SS_n,
	output 				SCLK,
	output 				MOSI,
	output logic		done,
	output [15:0]		rd_data
);
	// SCLK counter and signals
	logic [4:0] SCLK_div;
	logic SCLK_fall, SCLK_rise;
	
	// bit counter
	logic [3:0] bit_cnt;
	logic done15;
	
	// 16-bit shift register
	logic [15:0] shft_reg;
	logic MISO_smpl;

	// SM outputs
	logic smpl, init, shift, rst_cnt, set_done, ld_SCLK;
	
	typedef enum reg [1:0] { IDLE, SKIP, WAIT15, BP } state_t;
	state_t state, nxt_state;

	////////// SCLK datapath //////////
	// 5-bit SCLK counter
	always_ff @(posedge clk)
		if(ld_SCLK)
			SCLK_div <= 5'b10111;
		else
			SCLK_div <= SCLK_div + 1;
		
	assign SCLK = SCLK_div[4];
	
	// imminent fall/rise
	assign SCLK_fall = (SCLK_div == 5'b11111);
	assign SCLK_rise = (SCLK_div == 5'b01111);
	
	
	/////// bit counter datapath ///////
	always_ff @(posedge clk)
		if(init)
			bit_cnt <= 4'h0;
		else if(shift)
			bit_cnt <= bit_cnt + 1;
			
	assign done15 = &bit_cnt;
	

	////////// shift register /////////
	always_ff @(posedge clk)
		if(smpl)
			MISO_smpl <= MISO;

	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			shft_reg <= 16'hFFFF;
		else if(init)
			shft_reg <= wt_data;
		else if(shift)
			shft_reg <= {shft_reg[14:0],MISO_smpl};

	assign MOSI = shft_reg[15];
	

	////////// state machine //////////
	// state register
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	
	// output and transition logic
	always_comb begin
		// default outputs
		nxt_state = state;
		ld_SCLK = 0;
		init = 0;
		shift = 0;
		smpl = 0;
		set_done = 0;

		case(state)
			// wait for first SPI transaction
			IDLE: begin
				ld_SCLK = 1;
				if(wrt) begin
					init = 1;
					nxt_state = SKIP;
				end
			end

			// do not shift on first falling edge
			SKIP: begin
				if(SCLK_fall)
					nxt_state = WAIT15;
			end

			// sample on rise, shift on fall
			// done15 asserted before last bit is sampled
			WAIT15: begin
				if(done15)
					nxt_state = BP;
				else if(SCLK_rise)
					smpl = 1;
				else if(SCLK_fall)
					shift = 1;
			end

			// sample last bit and freeze SCLK on next imminent fall
			BP: begin
				if(SCLK_fall) begin
					set_done = 1;
					shift = 1;
					ld_SCLK = 1;
					nxt_state = IDLE;
				end 
				else if(SCLK_rise)
					smpl = 1;

			end
		endcase
	end
	
	// SR flop for done
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			done <= 0;
		else if(init)
			done <= 0;
		else if(set_done)
			done <= 1;

	// SR flop for SS_n
	always @(posedge clk, negedge rst_n)
		if(!rst_n)
			SS_n <= 1;
		else if(init)
			SS_n <= 0;
		else if(set_done)
			SS_n <= 1;

	assign rd_data = shft_reg;
endmodule
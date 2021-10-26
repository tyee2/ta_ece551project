module SPI_mnrch(
	input 				clk, rst_n,
	input 				wrt,
	input [15:0]		wt_data,
	input 				MISO,
	output 				SS_n,
	output 				SCLK,
	output 				MOSI,
	output 				done,
	output [15:0]		rd_data
);
	// SCLK counter and signals
	logic [4:0] SCLK_div;
	logic SCLK_ff1, SCLK_ff2;
	logic SCLK_fall, SCLK_rise;
	
	// bit counter
	logic [3:0] bit_cnt;
	logic done15;
	
	// 16-bit shift register
	logic [15:0] shft_reg;

	// SM outputs
	logic smpl, init, shift, rst_cnt, set_done, ld_SCLK;
	


	////////// SCLK datapath //////////
	// 5-bit SCLK counter (requires preset since SCLK normally high)
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			SCLK_div <= 5'h10;
		else if(ld_SCLK)
			SCLK_div <= 5'h17;
		else
			SCLK_div <= SCLK_div + 1;

	// falling edge detection of SCLK
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
			SCLK_ff1 <= 1;
			SCLK_ff2 <= 1;
		end 
		else begin
			SCLK_ff1 <= SCLK;
			SCLK_ff2 <= SCLK_ff1;
		end
		
	// SS_n
	always @(posedge clk, negedge rst_n)
		if(!rst_n)
			SS_n <= 1;
		else if(done15 && SCLK_fall)
			SS_n <= 1;
		else if(init)
			SS_n <= 0;
		
	assign SCLK = SCLK_div[4];
	assign shift = &SCLK_div;
	
	assign SCLK_fall = ~SCLK_ff1 & SCLK_ff2;
	assign SCLK_rise = SCLK_ff1 & ~SCLK_ff2;
	
	
	/////// bit counter datapath ///////
	always_ff @(posedge clk)
		if(init)
			bit_cnt <= 4'h0;
		else if(shift)
			bit_cnt <= bit_cnt + 1;
			
	assign done15 = &bit_cnt;
	
	////////// state machine //////////
	
	// SR flop for done
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			done <= 0;
		else if(init)
			done <= 0;
		else if(set_done)
			done <= 1;
endmodule
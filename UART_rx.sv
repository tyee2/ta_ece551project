module UART_rx(	
	input clk, rst_n, clr_rdy,
	input RX,
	output [7:0] rx_data,
	output reg rdy
);
	
	// SM logic
	typedef enum reg {IDLE, RECEIVE} state_t; 
	state_t state, nxt_state; 
	
	logic start, receiving, set_rdy, shift; 

	// shift register input/outputs
	logic RX_meta1, RX_meta2;
	logic [8:0] rx_shft_reg;

	// counters for baud rate and shift reg
	logic [3:0] bit_cnt;
	logic [11:0] baud_cnt, baud_cnt_start;	


	//////////////// counters ////////////////////
	// bit counter
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			bit_cnt <= 4'h0; 
		else if(start) 
			bit_cnt <= 4'h0; 
		else if(shift) 
			bit_cnt <= bit_cnt + 1;
	end
	
	// determine where to start baud counter
	always_comb begin
		if(start)
			baud_cnt_start = 12'h516; 
		else
			baud_cnt_start = 12'h000; 
	end
		
	// baud rate counter
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			baud_cnt <= 12'h000;
		else if (start || shift)
			baud_cnt <= baud_cnt_start; 
		else if(receiving)
			baud_cnt <= baud_cnt + 1; 
	end

	// shift after a baud cycle
	assign shift = (baud_cnt == 12'd2603); 
	

	///////// metastability flops for RX /////////
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			RX_meta1 <= 0;
			RX_meta2 <= 0;
		end
		
		else begin
			RX_meta1 <= RX;
			RX_meta2 <= RX_meta1;
		end
	end
	

	////////////// shift register ////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) 
			rx_shft_reg <= 9'h1FF; 

		else if(shift) 
			rx_shft_reg <= {RX_meta2, rx_shft_reg[8:1]}; 
	end

	// get rid of the stop bit
	assign rx_data = rx_shft_reg[7:0]; 
	
	
	////////////// state machine /////////////////
	// state flop
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			state <= IDLE; 
		else
			state <= nxt_state; 
	end

	// SM transition and output logic
	always_comb begin
		// default outputs and next state
		set_rdy = 0; 
		start = 0; 
		receiving = 0; 
		nxt_state = state; 

		case(state)
			RECEIVE: if(bit_cnt == 4'd10) begin
				set_rdy = 1; 
				nxt_state = IDLE; 
			end else begin
				receiving = 1; 
			end
			
			// default = IDLE		
			default: if(!RX_meta2) begin
				start = 1;
				nxt_state = RECEIVE; 
			end 
		endcase
	end
	
	// SR flop to ensure no glitches at output
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			rdy <= 1'b0; 
		else if (start || clr_rdy)
			rdy <= 1'b0; 
		else if(set_rdy)
			rdy <= 1'b1;
	end
endmodule
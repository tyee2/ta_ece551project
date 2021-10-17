module UART_tx(	
	input clk, rst_n,
	input trmt,
	input [7:0] tx_data,
	output reg TX, tx_done
);
	
	// SM logic
	typedef enum reg {IDLE, TRANSMIT} state_t; 
	state_t state, nxt_state; 
	
	logic load, transmitting, set_done, clr_done; 
	logic shift; 

	// shift register output
	logic [8:0] tx_shift_reg;

	// counters for baud rate and shift reg
	logic [3:0] bit_cnt;
	logic [11:0] baud_cnt;			


	//////////////// counters ////////////////////
	// counter to track # of bits sent
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			bit_cnt <= 4'h0; 
		else if(load) 
			bit_cnt <= 4'h0; 
		else if(shift) 
			bit_cnt <= bit_cnt + 1;
	end
		
	// baud rate counter
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			baud_cnt <= 12'h000;
		else if (load || shift)
			baud_cnt <= 12'h000; 
		else if(transmitting)
			baud_cnt <= baud_cnt + 1; 
	end

	// shift after a baud cycle
	assign shift = (baud_cnt == 12'd2603); 


	////////////// shift register ////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) 
			tx_shift_reg <= 9'h1FF; 
		else if(load)
			tx_shift_reg <= {tx_data, 1'b0}; 
		else if(shift) 
			tx_shift_reg <= {1'b1, tx_shift_reg[8:1]}; 
	end

	// output the LSB of the shift register
	assign TX = tx_shift_reg[0]; 
	
	
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
		load = 0; 
		transmitting = 0; 
		set_done = 0; 
		clr_done = 0;  
		nxt_state = state; 

		case(state)
			TRANSMIT: if(bit_cnt == 4'd10) begin
				set_done = 1; 
				nxt_state = IDLE;
			end else begin
				transmitting = 1; 
			end
			
			// default = IDLE		
			default: if(trmt) begin
				load = 1; 
				clr_done = 1; 
				nxt_state = TRANSMIT; 
			end 
		endcase
	end
	
	// SR flop to ensure no glitches at output
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			tx_done <= 1'b0; 
		else if (clr_done)
			tx_done <= 1'b0; 
		else if(set_done)
			tx_done <= 1'b1;
	end
endmodule
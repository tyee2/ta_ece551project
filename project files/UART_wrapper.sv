module UART_wrapper(
	input 				clk, rst_n,
	input 				RX,
	input 				clr_cmd_rdy,
	input 				trmt,
	input [7:0] 		resp,
	output 				TX,
	output 				cmd_rdy,
	output [15:0] 		cmd,
	output 				tx_done
);
	// SM states
	typedef enum reg {HIGH,LOW} state_t; 
	state_t state, nxt_state; 

	// SM inputs and outputs
	logic clr_rdy, rx_rdy;
	logic high_byte_rdy;
	
	logic [7:0] rx_data, high_byte;

	///// instantiate the UART /////
	UART iUART(
		.clk(clk),
		.rst_n(rst_n),
		.RX(RX),
		.trmt(trmt),
		.clr_rx_rdy(clr_rdy),
		.tx_data(resp),
		.TX(TX),
		.rx_rdy(rx_rdy),
		.tx_done(tx_done),
		.rx_data(rx_data)
	);
	
	///// state machine /////
	// state flop
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= HIGH;
		else
			state <= nxt_state;
	
	// state transition and output logic
	always_comb begin
		
	end
	
	// flop to save the high byte
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			high_byte <= 8'h00; 
		else if(high_byte_rdy)
			high_byte <= rx_data; 

endmodule	
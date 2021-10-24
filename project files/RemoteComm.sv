module RemoteComm(
	input 	clk, rst_n,
	input 	RX,
	input 	snd_cmd,
	input  	[15:0] cmd,
	
	output 	TX,
	output 	cmd_snt,
	output 	[7:0] resp,
	output 	resp_rdy
);
	// datapath signals
	logic [7:0] tx_data, low_byte;

	// SM states
	typedef enum reg [1:0] {HIGH,LOW} state_t;
	state_t state, nxt_state;

	// SM inputs
	logic tx_done;

	// SM outputs
	logic trmt, sel_high, clr_rx_rdy, set_cmd_snt;
	
	// instantiation of UART
	UART iUART(
		.clk(clk),
		.rst_n(rst_n),
		.RX(RX),
		.TX(TX),
		.rx_rdy(resp_rdy),
		.clr_rx_rdy(clr_rx_rdy),
		.rx_data(resp),
		.trmt(trmt),
		.tx_data(tx_data),
		.tx_done(tx_done)
	)
	
	//////////// Datapath /////////////
	assign tx_data = sel_high ? cmd[15:8] : low_byte;
	
	// high byte sent first, so store low byte
	always_ff @(posedge clk)
		if(snd_cmd)
			low_byte <= cmd[7:0];
	
	// SR flop for cmd_rdy
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			cmd_rdy <= 0;
		else if(snd_cmd)
			cmd_rdy <= 0;
		else if(set_cmd_rdy)
			cmd_rdy <= 1;
	end
	
	////////// State machine //////////
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;

	// output and transition logic
	always_comb begin
		// default outputs
		nxt_state = state;
		sel_high = 0;
		clr_rx_rdy = 0;
		trmt = 0;
		set_cmd_rdy = 0;
		
		case(state)
			default: // IDLE
				if(snd_cmd) begin
					sel_high = 1;
					trmt = 1;
					clr_rx_rdy = 1;
					nxt_state = HIGH;
				end

			HIGH: 
				if(tx_done) begin
					trmt = 1;
					nxt_state = LOW;
				end

			LOW: begin
				if(tx_done) begin
					set_cmd_rdy = 1;
					nxt_state = IDLE;
				end
			end
		endcase
	end

endmodule
module UART_tb(); 

	logic clk, rst_n; 
	logic TX_to_RX, trmt, clr_rdy; 
	logic [7:0] tx_data, rx_data; 
	logic tx_done, rdy; 

	// instantiate the UART
	UART_rx iRECEIVE(.clk(clk), .rst_n(rst_n), .RX(TX_to_RX), .clr_rdy(clr_rdy), .rx_data(rx_data), .rdy(rdy)); 
	UART_tx iTRANSMIT(.clk(clk), .rst_n(rst_n), .TX(TX_to_RX), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done)); 

	initial begin
		
		clk = 1'b0; 
		rst_n = 1'b0; 	
		clr_rdy = 1'b1; 
		
		@(negedge clk);
		rst_n = 1'b1; 
		clr_rdy = 1'b0; 
		trmt = 1'b1; 
		tx_data = 8'hAA;

		@(negedge clk);
		trmt = 1'b0;		// deasserting trmt to stay in IDLE state after TRANSMIT is finished

		// Testing functionality of tx_done and the sending/receiving of information	
		fork
			begin: timeout_tx1
				repeat(100000) @(posedge clk);
				$display("ERROR: transmission never completed after 100000 cycles. check your SM for UART_tx.");
				$stop;
			end
			
			begin: timeout_rx1
				repeat(100000) @(posedge clk);
				$display("ERROR: receiver never asserted rdy after 100000 cycles. check your SM for UART_rx.");
				$stop;
			end
			
			begin
				@(posedge rdy) disable timeout_rx1;
				@(posedge tx_done) disable timeout_tx1;
				
				assert(rx_data == tx_data) $display("PASS: rx_data matches tx_data for 0xAA.");
				else begin
					$display("ERROR: Data was not sent and received properly. rx_data was %h and tx_data was %h", rx_data, tx_data); 
					$stop;
				end
			end
		join
		
		// Testing functionality of clr_rdy, ensuring rdy stays low after clr_rdy is de-asserted
		@(negedge clk);
		clr_rdy = 1'b1;
		repeat(2) @(posedge clk);
		if(rdy) begin
			$display("ERROR: After asserting clr_rdy, rdy should be low"); 
			$stop; 
		end

		@(negedge clk);
		clr_rdy = 1'b0;
		@(posedge clk);
		if(rdy) begin
			$display("ERROR: Even after clr_rdy goes low, rdy should remain low if clr_rdy was asserted"); 
			$stop; 
		end

		// Testing new tx_data after first transmission
		@(negedge clk);
		trmt = 1'b1; 
		tx_data = 8'h78;

		@(negedge clk);
		trmt = 1'b0; 		// deasserting trmt to stay in IDLE state after TRANSMIT is finished

		fork
			begin: timeout_tx2
				repeat(100000) @(posedge clk);
				$display("ERROR: transmission never completed after 100000 cycles. check your SM for UART_tx.");
				$stop;
			end
			
			begin: timeout_rx2
				repeat(100000) @(posedge clk);
				$display("ERROR: receiver never asserted rdy after 100000 cycles. check your SM for UART_rx.");
				$stop;
			end
			
			begin
				@(posedge rdy) disable timeout_rx2;
				@(posedge tx_done) disable timeout_tx2;
				
				assert(rx_data == tx_data) $display("PASS: rx_data matches tx_data for 0x78.");
				else begin
					$display("ERROR: Data was not sent and received properly. rx_data was %h and tx_data was %h", rx_data, tx_data); 
					$stop;
				end
			end
		join
		
		$display("All tests passed."); 
		$stop; 
	end
	
	always #5 clk = ~clk;
	
endmodule

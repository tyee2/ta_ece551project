module UART_tx_tb(); 

	logic clk, rst_n; 
	logic trmt;
	logic [7:0] tx_data; 
	logic TX, tx_done; 
	
	UART_tx iDUT(
		.clk(clk), 
		.rst_n(rst_n), 
		.trmt(trmt), 
		.tx_data(tx_data), 
		.TX(TX), 
		.tx_done(tx_done)
	); 


	initial begin

		clk = 1'b1; 
		rst_n = 1'b0; 

		@(negedge clk);
		rst_n = 1'b1; 
		
		trmt = 1'b1; 
		tx_data = 8'h0A; 
		@(posedge clk)
		trmt = 1'b0; 
	
		// Wait until tx_done is asserted before trying to send new byte of information
		@(posedge tx_done);
		
		@(posedge clk);
		tx_data = 8'h55; 
		@(posedge clk);
		trmt = 1'b1;
		@(posedge clk);
		trmt = 1'b0; 
		
		// Testing that another byte of information is sent
		@(posedge tx_done);
		
		repeat(10000) @(posedge clk);

		$stop; 
	end
	
	always #5 clk <= ~clk;

endmodule

module SDiv_tb();

	// DUT inputs
	logic clk, rst_n, go;
	logic signed [15:0] dividend, divisor;
	
	// DUT outputs
	logic signed [15:0] quotient;
	logic rdy;
	
	// instantiate DUT
	SDiv iDUT(
		.clk(clk), 
		.rst_n(rst_n),
		.go(go),
		.dividend(dividend), // numerator
		.divisor(divisor),   // denominator
		.quotient(quotient),
		.rdy(rdy)
	);
	
	initial begin
		clk = 0;
		rst_n = 0;
		go = 0;
		dividend = 25;
		divisor = 5;
		
		@(posedge clk);
		@(negedge clk);
		rst_n = 1;
		
		// TEST 0: reset
		if(quotient != 0) begin
			$display("ERROR: reset did not clear quotient");
			$stop;
		end
		else if(rdy != 0) begin
			$display("ERROR: reset did not clear rdy");
			$stop;
		end 
		else
			$display("TEST 0: RESET [OK]");
		
		@(posedge clk);
		
		// TEST 1: 25/5 = 5
		go = 1;
		@(posedge clk);
		go = 0;
		@(posedge rdy);
		if(quotient != 5) begin
			$display("ERROR: incorrect result for 25/5. expected 5, got %d", quotient);
			$stop;
		end else
			$display("TEST 1: got %d for 25/5 [OK]", quotient);
		
		// hold test
		repeat(5)@(posedge clk); 
		
		if(rdy != 1) begin
			$display("rdy went low before go was asserted");
			$stop;
		end else
			$display("rdy held until next go [OK]");
		
		@(posedge clk);
		
		// TEST 2: -100/10 = -10
		dividend = -100;
		divisor = 10;
		go = 1;
		@(posedge clk);
		go = 0;
		@(posedge rdy);
		if(quotient != -10) begin
			$display("ERROR: incorrect result for -100/10. expected -10, got %d", quotient);
			$stop;
		end else
			$display("TEST 2: got %d for -100/10 [OK]", quotient);
		
		@(posedge clk);
		
		// TEST 3: 64/-32 = -2
		dividend = 64;
		divisor = -32;
		go = 1;
		@(posedge clk);
		go = 0;
		@(posedge rdy);
		if(quotient != -2) begin
			$display("ERROR: incorrect result for 64/-32. expected -2, got %d", quotient);
			$stop;
		end else
			$display("TEST 3: got %d for 64/-32 [OK]", quotient);
		
		@(posedge clk);
		
		// TEST 4: -30/-10 = 3
		dividend = -30;
		divisor = -10;
		go = 1;
		@(posedge clk);
		go = 0;
		@(posedge rdy);
		if(quotient != 3) begin
			$display("ERROR: incorrect result for -30/-10. expected 3, got %d", quotient);
			$stop;
		end else
			$display("TEST 4: got %d for -30/-10 [OK]", quotient);
		
		$display("All tests passed.");
		$stop;
		
	end
	
	always #5 clk = ~clk;
	
endmodule
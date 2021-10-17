module I_term_tb();

	// DUT stimuli
	reg clk, rst_n, moving, err_vld;
	reg [9:0] err_sat;
	
	// DUT output(s)
	wire [8:0] I_term;
	
	// temp result
	reg [8:0] tmp;
	
	// instantiate DUT
	I_term iDUT(.clk(clk),.rst_n(rst_n),.moving(moving),.err_vld(err_vld),.err_sat(err_sat),.I_term(I_term));

	initial begin
		clk = 0;
		rst_n = 0;
		moving = 1;
		err_vld = 1;
		err_sat = 10'h0FF;
		@(posedge clk);
		@(negedge clk);
		rst_n = 1; // deassert reset
		repeat(10) @(posedge clk);
		
		// test 1: freeze integrator if err_vld = 0
		err_vld = 0;
		@(posedge clk);
		tmp = I_term;
		repeat(5) @(posedge clk);
		if(I_term != tmp) begin
			$display("ERROR: integrator was not frozen for invalid error!");
			$stop;
		end
			
		// clear test 1
		@(posedge clk);
		moving = 1;
		err_vld = 1;
		repeat(5) @(posedge clk);
		
		// test 2: clearing the accumulator when not moving
		moving = 0;
		repeat(5) @(posedge clk);
		if(I_term != 0) begin
			$display("ERROR: accumulator was not cleared for moving=0!");
			$stop;
		end
		repeat(5) @(posedge clk);
		
		// test 3: freeze integrator if overflow
		moving = 1;
		err_vld = 1;
		err_sat = 10'h1FF;
		repeat(100) @(posedge clk); // should've overflowed by now.
		tmp = I_term;
		repeat(5) @(posedge clk); // integrator should hold prev. value...
		if(I_term != tmp) begin
			$display("ERROR: integrator was not frozen for overflow!");
			$stop;
		end
		
		// if you got here, good job.
		$display("congrats, you didn't fuck this up!");
		
		$stop;
	end
	
	always #5 clk = ~clk;
	
endmodule
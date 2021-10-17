// Discussion 4 - clock generators

module clk_gen_tb();
	logic clk1, clk2, clk3;
	
	initial begin
		clk1 = 0;
		clk2 = 0;
		clk3 = 0;
		
		#1000;
		$stop;
	end
	
	// clock generator 1
	always 
		#10 clk1 = ~clk1;
	
	// clock generator 2 -- what is wrong with this one?
	always @(clk2)
		#10 clk2 = ~clk2;
		
	// clock generator 3
	always @(clk3)
		clk3 <= #10 ~clk3;
	
endmodule
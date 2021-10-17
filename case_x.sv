module case_x();
	logic clk;
	logic [2:0] exp_x;
	
	always_comb begin
		casex(exp_x)
			3'b0xx: $display("case 1");
			3'b10x: $display("case 2");
			3'b111: $display("case 3");
			default:$display("default case");
		endcase
	end
	
	
	initial begin
		clk = 0;
		$display("TEST: 001");
		exp_x = 3'b001;

		@(posedge clk);
		
		$display("TEST: 010");
		exp_x = 3'b101;

		@(posedge clk);
		
		$display("TEST: 1x1");
		exp_x = 3'b1x1;

		@(posedge clk);
		
		$display("TEST: 1xx");
		exp_x = 3'b1xx;

		@(posedge clk);
		
		$display("TEST: 0x1");
		exp_x = 3'b0x1;

		@(posedge clk);
		
		$display("TEST: xx0");
		exp_x = 3'bxx0;

		@(posedge clk);
		
		$display("TEST: x00");
		exp_x = 3'bx00;

		@(posedge clk);
		
		$stop;
	end
	
	always #5 clk = ~clk;
	
endmodule
module test();
logic clk, rst;
logic [7:0] rnd;
logic next;

always @(posedge clk) 
  if (rst) 
    rnd <= 8'h01; 
  else if (next) 
    rnd <= {rnd[6:0],rnd[7]^ ^rnd[3:1]};
	
initial begin
	clk = 0;
	rst = 1;
	@(posedge clk);
	rst = 0;
	next = 1;
	repeat(3) @(posedge clk);
	$stop;
end


always #5 clk = ~clk;

endmodule
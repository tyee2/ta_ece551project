module inert_intf_tb();
	logic clk;
	logic rst_n;
	logic strt_cal;         // from cmd_proc
	logic INT;              // from inertial sensor; needs double flop
	logic moving;
	logic lftIR;            // left guardrail
	logic rghtIR;           // right guardrail
	logic MISO;             // from inertial sensor
	logic cal_done;
	logic rdy;
	logic signed [11:0] heading;
	logic SS_n;
	logic SCLK;
	logic MOSI;
	
	// instantiate DUT and serf
	inert_intf iDUT(
		.*,
		.moving(1'b1),
		.lftIR(1'b0),
		.rghtIR(1'b0)
	);
	
	SPI_iNEMO2 iNEMO(
		.*
	);
	
	initial begin
	
		// reset sequence
		clk = 0;
		rst_n = 0;
		strt_cal = 0;
		@(posedge clk);
		@(negedge clk);
		rst_n = 1;
		
		// wait until NEMO_setup gets asserted before asserting strt_cal
		fork
			begin: timeout
				repeat(100000) @(posedge clk);
				$display("ERR: timed out waiting for NEMO_setup");
				$stop();
			end
			begin
				@(posedge iNEMO.NEMO_setup);
				disable timeout;
			end
		join
		strt_cal = 1;
		@(posedge clk);
		strt_cal = 0;
		
		wait4sig(cal_done,1000000);
		
		repeat(8000000) @(posedge clk);
		
		$stop;
		
	end
	
	always #5 clk = ~clk;
	`include "tb_tasks.sv"
endmodule
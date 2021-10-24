module CommTB();
    
    logic clk, rst_n;
    logic TX_RX;
    logic RX_TX;
    logic [15:0] cmd_in, cmd_out;
    logic snd_cmd, cmd_snt, clr_cmd_rdy;
    logic trmt, tx_done, cmd_rdy;

    // instantiate both RemoteComm and UART_wrapper
    RemoteComm iTX(
        .clk(clk), 
        .rst_n(rst_n),
        .RX(RX_TX),
        .snd_cmd(snd_cmd),
        .cmd(cmd_in),
        .TX(TX_RX),
        .cmd_snt(cmd_snt),
        .resp(), // not testing response
        .resp_rdy() // not testing response
    );

    UART_wrapper iRX(
        .clk(clk), 
        .rst_n(rst_n),
        .RX(TX_RX),
        .clr_cmd_rdy(clr_cmd_rdy),
        .trmt(trmt),
        .resp(0), // not testing response
        .TX(), // not testing response
        .cmd_rdy(cmd_rdy),
        .cmd(cmd_out),
        .tx_done(tx_done)
    );

    initial begin
		
		clk = 1'b0; 
		rst_n = 1'b0; 	
        clr_cmd_rdy = 1'b0;
        trmt = 0;
		
		@(negedge clk);
		rst_n = 1'b1; 
		snd_cmd = 1'b1; 
		cmd_in = 16'hABCD;

		@(negedge clk);
		snd_cmd = 1'b0;

        $display("TEST 1: sending and receiving functionality for cmd=%h",cmd_in);
		fork
			begin: timeout_tx1
				repeat(100000) @(posedge clk);
				$display("ERROR: transmission never completed after 100000 cycles.");
				$stop;
			end
			
			begin: timeout_rx1
				repeat(100000) @(posedge clk);
				$display("ERROR: receiver never asserted rdy after 100000 cycles.");
				$stop;
			end
			
			begin
				@(posedge cmd_rdy) disable timeout_rx1;
				@(posedge cmd_snt) disable timeout_tx1;
				
				assert(cmd_in === cmd_out) 
                    $display("PASS: cmd received is the same as the cmd sent. cmd: %h", cmd_in);
				else begin
					$display("ERROR: Data was not sent and received properly. " +
                    "cmd received was %h and cmd sent was %h", cmd_out, cmd_in); 
					$stop;
				end
			end
		join

        @(negedge clk);
        snd_cmd = 1'b1; 
		cmd_in = 16'h1234;

		@(negedge clk);
		snd_cmd = 1'b0;

        $display("TEST 2: deasserting cmd_rdy with another command." +
        "testing sending/receiving functionality for cmd=%h.",cmd_in);
		fork
			begin: timeout_tx2
				repeat(100000) @(posedge clk);
				$display("ERROR: transmission never completed after 100000 cycles.");
				$stop;
			end
			
			begin: timeout_rx2
				repeat(100000) @(posedge clk);
				$display("ERROR: receiver never asserted rdy after 100000 cycles.");
				$stop;
			end
			
			begin
				@(posedge cmd_rdy) disable timeout_rx2;
				@(posedge cmd_snt) disable timeout_tx2;
				
				assert(cmd_in === cmd_out) 
                    $display("PASS: cmd received is the same as the cmd sent. cmd: %h", cmd_in);
				else begin
					$display("ERROR: Data was not sent and received properly. " +
                    "cmd received was %h and cmd sent was %h", cmd_out, cmd_in); 
					$stop;
				end

                assert(cmd_rdy === 0) 
                    $display("PASS: cmd_rdy was deasserted properly.");
				else begin
					$display("ERROR: cmd_rdy was not deasserted with another cmd."); 
					$stop;
				end
			end
		join

        $display("TEST 3: asserting clr_cmd_rdy");
        @(negedge clk);
        snd_cmd = 1'b1; 
		cmd_in = 16'hFFFF;

		@(negedge clk);
		snd_cmd = 1'b0;
        fork
			begin: timeout_tx3
				repeat(100000) @(posedge clk);
				$display("ERROR: transmission never completed after 100000 cycles.");
				$stop;
			end
			
			begin: timeout_rx3
				repeat(100000) @(posedge clk);
				$display("ERROR: receiver never asserted rdy after 100000 cycles.");
				$stop;
			end
			
			begin
				@(posedge cmd_rdy) disable timeout_rx3;
				@(posedge cmd_snt) disable timeout_tx3;
				
				assert(cmd_in === cmd_out) 
                    $display("PASS: cmd received is the same as the cmd sent. cmd: %h", cmd_in);
				else begin
					$display("ERROR: Data was not sent and received properly. " +
                    "cmd received was %h and cmd sent was %h", cmd_out, cmd_in); 
					$stop;
				end
			end
		join

        repeat(100) @(negedge clk);
        clr_cmd_rdy = 1'b1;
        @(negedge clk);
        clr_cmd_rdy = 1'b0;
        @(posedge clk);
        @(negedge clk);

        assert(cmd_rdy === 0)
            $display("PASS: cmd_rdy knocked down by clr_cmd_rdy");
        else begin
            $display("ERROR: cmd_rdy was not deasserted by clr_cmd_rdy");
            $stop;
        end

        $display("All tests passed, good job.");
        $stop;
    end

    always #5 clk = ~clk;

endmodule
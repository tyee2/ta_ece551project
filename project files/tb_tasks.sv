package tb_tasks;

  ////// define localparms for command encoding /////
  localparam CAL_CMD = 16'h0000;
  localparam MOV_NORTH = 16'h2000;
  localparam MOV_WEST = 16'h23F0;
  localparam MOV_SOUTH = 16'h27F0;
  localparam MOV_EAST = 16'h2BF0;
  localparam WITH_FANFARE = 16'h1000;	// OR this in with cmd to make it w FANFARE
  localparam KNIGHTS_TOUR = 16'h4000;
  
  ///////////////////////////////////////////////////////
  // Initialize clk and inputs, assert/deassert reset //
  /////////////////////////////////////////////////////
  task automatic Initialize(ref clk,RST_n,send_cmd, ref [15:0]cmd);
    clk = 1'b0;
	RST_n = 1'b0;
	send_cmd = 1'b0;
	cmd = CAL_CMD;
	@(negedge clk);
	RST_n = 1'b1;		// deassert reset
	repeat(2) @(negedge clk);
  endtask
  
  /////////////////////////////
  // Task to send a command //
  ///////////////////////////
  task automatic SndCmd(input [15:0] cmd2send, ref clk,send_cmd,cmd_sent, ref [15:0]cmd);
    cmd = cmd2send;
	@(negedge clk);
	send_cmd = 1'b1;
	@(negedge clk);
	send_cmd = 1'b0;
	@(posedge cmd_sent);
    $display("INFO: cmd = %h successfully sent",cmd2send);
	@(negedge clk);
  endtask

  //////////////////////////////////////////////////////////////////
  // Task to wait for response to cmd and check against expected //
  ////////////////////////////////////////////////////////////////
  task automatic ChkResp(input [7:0] expected, ref clk,resp_rdy, ref [7:0] resp);
	  /////////////////////////////////////////////
	  // Waits for response from DUT and checks //
	  // it against the expected result.       //
	  //////////////////////////////////////////
	  $display("INFO: waiting for response on resp_rdy");
	  wait4Sig(resp_rdy,clk,2750000);
	  if (resp!==expected)
	    begin
		  $display("ERROR: Response of %h did not match expected response of %h\n",resp,expected);
		  $stop();
        end
      @(negedge clk);
  endtask

  //////////////////////////////////////////////////////////////////
  // Task to wait for response to cmd and check against expected //
  ////////////////////////////////////////////////////////////////
  task automatic ChkRespLong(input [7:0] expected, ref clk,resp_rdy, ref [7:0] resp);
	  /////////////////////////////////////////////
	  // Waits for response from DUT and checks //
	  // it against the expected result.       //
	  //////////////////////////////////////////
	  $display("INFO: waiting for response on resp_rdy");
	  wait4Sig(resp_rdy,clk,5750000);
	  if (resp!==expected)
	    begin
		  $display("ERROR: Response of %h did not match expected response of %h\n",resp,expected);
		  $stop();
        end
      @(negedge clk);
  endtask
  
  
  ////////////////////////////////////
  // Task to check Knight position //
  //////////////////////////////////
  task automatic ChkPos(input [2:0] exp_x,exp_y, input [6:0] xx,yy);
    if ((xx>{exp_x,4'h5}) && (xx<{exp_x,4'hB}) && 
	   (yy>{exp_y,4'h5}) && (yy<{exp_y,4'hB}))
	  $display("GOOD: xx,yy as expected");
	else begin
	  $display("ERROR: xx = %h and yy = %h, expected near center of %d,%d",xx,yy,exp_x,exp_y);
	  $stop();
	end
  endtask 


  ////////////////////////////////////////////////////////
  // Generic task to wait for a sig to rise or timeout //
  //////////////////////////////////////////////////////
  task automatic wait4Sig(ref sig,clk, input int clks2wait);
	  fork
		begin: timeout
		  repeat(clks2wait) @(posedge clk);
		  $display("Err timed out waiting for sig in task wait4Sig");
		  $stop();
		end
		begin
		  @(posedge sig);
		  disable timeout;
		end
	  join
  endtask

endpackage

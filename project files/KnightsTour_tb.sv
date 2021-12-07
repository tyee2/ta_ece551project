module KnightsTour_tb();

  import tb_tasks::*;			// import all definitions and tasks
  
  localparam FAST_SIM = 1;
  
  
  /////////////////////////////
  // Stimulus of type reg //
  /////////////////////////
  reg clk, RST_n;
  reg [15:0] cmd;
  reg send_cmd;
  
  ///////////////////////////////////
  // Declare any internal signals //
  /////////////////////////////////
  wire SS_n,SCLK,MOSI,MISO,INT;
  wire lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;
  wire TX_RX, RX_TX;
  logic cmd_sent;
  logic resp_rdy;
  logic [7:0] resp;
  wire IR_en;
  wire lftIR_n,rghtIR_n,cntrIR_n;
  
  //////////////////////
  // Instantiate DUT //
  ////////////////////
  KnightsTour iDUT(.clk(clk), .RST_n(RST_n), .SS_n(SS_n), .SCLK(SCLK),
                   .MOSI(MOSI), .MISO(MISO), .INT(INT), .lftPWM1(lftPWM1),
				   .lftPWM2(lftPWM2), .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
				   .RX(TX_RX), .TX(RX_TX), .piezo(piezo), .piezo_n(piezo_n),
				   .IR_en(IR_en), .lftIR_n(lftIR_n), .rghtIR_n(rghtIR_n),
				   .cntrIR_n(cntrIR_n));
				  
  /////////////////////////////////////////////////////
  // Instantiate RemoteComm to send commands to DUT //
  ///////////////////////////////////////////////////
  RemoteComm iRMT(.clk(clk), .rst_n(RST_n), .RX(RX_TX), .TX(TX_RX), .cmd(cmd),
             .send_cmd(send_cmd), .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(resp));
				   
  //////////////////////////////////////////////////////
  // Instantiate model of Knight Physics (and board) //
  ////////////////////////////////////////////////////
  KnightPhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                      .MOSI(MOSI),.INT(INT),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),
					  .rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),.IR_en(IR_en),
					  .lftIR_n(lftIR_n),.rghtIR_n(rghtIR_n),.cntrIR_n(cntrIR_n)); 
				   
  initial begin
    Initialize(clk,RST_n,send_cmd,cmd);			// initialize signals and reset
	

    SndCmd(CAL_CMD,clk,send_cmd,cmd_sent,cmd);	// send CAL command
    ChkResp(8'hA5,clk,resp_rdy,resp);			// check A5 eventually returned

    $display("INFO: Sending MOV_EAST Command");
    SndCmd(MOV_EAST|16'h0001,clk,send_cmd,cmd_sent,cmd);	// tell it to move east 1
    repeat(3000000) @(negedge clk);				// must give it more time on move cmd
    ChkResp(8'hA5,clk,resp_rdy,resp);			// check A5 eventually returned
    repeat(250000) @(negedge clk);

    ChkPos(3'h3,3'h2,iPHYS.xx[14:8],iPHYS.yy[14:8]);	// expect xx=1, yy=2
	
    repeat(50000) @(negedge clk);

    $display("----------------------");
    $display("YAHOO!! Test3 Passed!!");
    $display("----------------------");
	
    @(negedge clk);
    $stop();

  end
  
  always
    #5 clk = ~clk;
  
endmodule

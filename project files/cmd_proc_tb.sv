module cmd_proc_tb();
    parameter FAST_SIM = 1;
    //////////////////////////////////////// tb signals ////////////////////////////////////////
    // global signals
    logic clk;                          // 50 MHz system clock
    logic rst_n;                        // active low async reset

    // cmd_proc
    logic [15:0] cmd_out;               // from UART_wrapper, contains received 16-bit command
    logic cmd_rdy;                      // from UART_wrapper, asserted when cmd is ready
    logic cal_done;                     // gyro calibration done
    logic heading_rdy;                  // pulse 1 clock cycle for valid heading
    logic lftIR;                        // err_nudge +
    logic cntrIR;                       // line crossing
    logic rghtIR;                       // err_nudge -
    logic [11:0] heading;               // gyro heading
    logic signed [11:0] error;          // to PID (heading - desired_heading)
    logic clr_cmd_rdy;                  // to UART_wrapper, knocks down cmd_rdy
    logic send_resp;                    // finished cmd, send response to UART_wrapper
    logic strt_cal;                     // to inert_intf, start gyro calibration
    logic [9:0] frwrd;                  // forward speed
    logic moving;                       // to inert_intf, yaw integration valid
    logic tour_go;                      // to TourCmd, solve Knight's Tour
    logic fanfare_go;                   // to charge, starts fanfare

    // RemoteComm and UART_wrapper
    logic [15:0] cmd_in;                // to RemoteComm, contains 16-bit command to send
    logic snd_cmd;                      // to RemoteComm, starts transmitting a command
    logic [7:0] resp;                   // from RemoteComm, should receive A5
    logic TX_to_RX;                     // RemoteComm -> UART_wrapper
    logic RX_to_TX;                     // UART_wrapper -> RemoteComm
    logic cmd_snt;                      // from RemoteComm, command was sent
    logic resp_rdy;                     // from RemoteComm, A5 response received
    logic tx_done;                      // from UART_wrapper, response was sent

    // inert_intf
    logic INT;                          // new data interrupt
    logic MOSI;                         // serial data from monarch to serf
    logic MISO;                         // serial data from serf to monarch
    logic SCLK;                         // 1/32 of system clock
    logic SS_n;                         // active low serf select

    // localparams for testing commands
    localparam CMD_CAL = 16'h0000;      // gyro calibration
    localparam CMD_MV_N1 = 16'h2001;    // move north 1
    localparam CMD_MV_N1C = 16'h3001;   // move north 1 with fanfare

    ////////////////////////////////////// instantiations //////////////////////////////////////
    cmd_proc #(FAST_SIM) iCMD(
        .clk(clk),
        .rst_n(rst_n),
        .cmd(cmd_out),
        .cmd_rdy(cmd_rdy),
        .cal_done(cal_done),
        .heading_rdy(heading_rdy),
        .lftIR(lftIR),
        .cntrIR(cntrIR),
        .rghtIR(rghtIR),
        .heading(heading),
        .error(error),
        .clr_cmd_rdy(clr_cmd_rdy),
        .send_resp(send_resp),
        .strt_cal(strt_cal),
        .frwrd(frwrd),
        .moving(moving),
        .tour_go(tour_go),
        .fanfare_go(fanfare_go)
    );

    RemoteComm iCOMM(
        .clk(clk),
        .rst_n(rst_n),
        .RX(RX_to_TX),
        .snd_cmd(snd_cmd),
        .cmd(cmd_in),
        .TX(TX_to_RX),
        .cmd_snt(cmd_snt),
        .resp(resp),
        .resp_rdy(resp_rdy)
    );

    UART_wrapper iRCV(
        .clk(clk),
        .rst_n(rst_n),
        .RX(TX_to_RX),
        .clr_cmd_rdy(clr_cmd_rdy),
        .trmt(send_resp),
        .resp(8'hA5),
        .TX(RX_to_TX),
        .cmd_rdy(cmd_rdy),
        .cmd(cmd_out),
        .tx_done(tx_done)
    );

    inert_intf #(FAST_SIM) iINTF(
        .clk(clk),
        .rst_n(rst_n),
        .strt_cal(strt_cal),
        .INT(INT),
        .moving(moving),
        .lftIR(lftIR),
        .rghtIR(rghtIR),
        .MISO(MISO),
        .cal_done(cal_done),
        .rdy(heading_rdy),
        .heading(heading),
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI)
    );

    SPI_iNEMO3 iNEMO(
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MISO(MISO),
        .MOSI(MOSI),
        .INT(INT)
    );
    //////////////////////////////////// end instantiations ////////////////////////////////////
    ////////////////////////////////////////// tests ///////////////////////////////////////////
    initial begin
        // initialize everything
        clk = 0;
        rst_n = 0;
        cmd_in = 0;
        snd_cmd = 0;
        lftIR = 0;
        cntrIR = 0;
        rghtIR = 0;
        @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        // test 1: gyro calibration
        $display("Starting test for gyro calibration...");
        send(CMD_CAL);
        $display("Checking for cal_done...");
        wait4sig(cal_done,500000);
        $display("Checking for resp_rdy...");
        wait4sig(resp_rdy,500000);

        if(resp !== 8'hA5) begin
            $display("Expected 8'hA5 response, actual resp received was %h",resp);
            $stop;
        end
        else begin
            $display("Calibration response passed!");
        end

        // test 2: move north 1 square
        $display("Testing move north 1 square...");
        send(CMD_MV_N1);
        $display("Checking for cmd_snt...");
        wait4sig(cmd_snt,500000);
        if(frwrd !== 10'h000) begin
            $display("ERROR: frwrd was not set to 0.");
            $stop;
        end

        $display("Waiting for 10 positive edges of heading_rdy...");
        repeat(10) @(posedge heading_rdy);
        if(!(frwrd === 10'h120 || frwrd === 10'h140)) begin
            $display("ERROR: frwrd should be either 10'h120 or 10'h140, but got %h",frwrd);
            $stop;
        end
        else
            $display("Passed, frwrd was %h",frwrd);

        $display("Checking for moving...");
        if(moving !== 1) begin
            $display("ERROR: moving is not asserted.");
            $stop;
        end

        // wait for ramp up to max speed
        $display("Waiting for 25 rising edges of heading_rdy to saturate max speed.");
        repeat(25) @(posedge heading_rdy);
        if(frwrd !== 10'h300) begin
            $display("ERROR: speed to not saturate to max.");
            $stop;
        end

        // pulse on cntrIR to indicate one line crossing, frwrd should still remain at max speed
        $display("Crossing a line...");
        @(posedge clk);
        cntrIR = 1;
        repeat(10000) @(posedge clk);
        cntrIR = 0;
        repeat(5) @(posedge heading_rdy);
        if(frwrd !== 10'h300) begin
            $display("ERROR: frwrd is not at max speed after crossing a line.");
            $stop;
        end

        // second line crossing, frwrd should decrement to 0
        $display("Crossing a second line...");
        @(posedge clk);
        cntrIR = 1;
        @(posedge clk);
        cntrIR = 0;
        repeat(3) @(posedge heading_rdy);
        if(!(frwrd < 10'h300)) begin
            $display("ERROR: frwrd did not decrement after crossing second line. frwrd: %h",frwrd);
            $stop;
        end

        // robot should not be moving when move_done asserted
        $display("Checking for movement when move_done asserted...");
        wait4sig(resp_rdy,500000);
        if((frwrd !== 0) || moving) begin
            $display("ERROR: frwrd/moving nonzero when move_done. frwrd: %h, moving",frwrd,moving);
            $stop;
        end

        // test 3: testing guardrail sensors
        $display("Sending a second move command...");
        send(CMD_MV_N1);
        repeat(25) @(posedge heading_rdy);
        $display("Saturated to max speed. Testing lftIR sensor...");
        @(posedge clk);
        lftIR = 1;
        repeat(500) @(posedge clk);
        lftIR = 0;
        if(error > 12'shFD0 && error < 12'sh030) begin
            $display("ERROR: lftIR did not affect error.");
            $stop;
        end 
        else
            $display("Passed, error was %h after 500 cycles.",error);

        $display("Testing rghtIR sensor...");
        @(posedge clk);
        rghtIR = 1;
        repeat(500) @(posedge clk);
        rghtIR = 0;
        if(error > 12'shFD0 && error < 12'sh030) begin
            $display("ERROR: rghtIR did not affect error.");
            $stop;
        end
        else
            $display("Passed, error was %h after 500 cycles.",error);

        $display("All cmd_proc tests passed!");
        $stop;
    end
    
    always #5 clk = ~clk;
    ////////////////////////////////////////// tasks ///////////////////////////////////////////
    // sends a 16-bit command
    task send(input [15:0] input_cmd);
        begin
            cmd_in = input_cmd;
            @(posedge clk);
            snd_cmd = 1;
            @(posedge clk);
            snd_cmd = 0;
        end
    endtask

    // timeout
    task automatic wait4sig(ref sig, input int clks2wait);
        fork
            begin: timeout
                repeat(clks2wait) @(posedge clk);
                $display("ERROR: timed out");
                $stop();
            end
            begin
                @(posedge sig); // signal of interest asserted
                disable timeout;
            end
        join
    endtask

endmodule
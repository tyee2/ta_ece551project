module TourCmd_tb();
    // DUT inputs
    logic clk;
    logic rst_n;
    logic start_tour;
    logic [7:0] move;
    logic [15:0] cmd_UART;
    logic cmd_rdy_UART;
    logic clr_cmd_rdy;
    logic send_resp;

    // DUT outputs
    logic [4:0] mv_indx;
    logic [15:0] cmd;
    logic cmd_rdy;
    logic [7:0] resp;

    TourCmd iTCmd(
        .*
    );

    initial begin
        clk = 0;
        rst_n = 0;
        start_tour = 0;
        cmd_UART = 16'hBEAD;
        cmd_rdy_UART = 0;
        clr_cmd_rdy = 0;
        send_resp = 0;
        move = 8'b0000_0100;
        @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        repeat(10) @(posedge clk);
        start_tour = 1;
        @(posedge clk);
        start_tour = 0;
        
        for(int i = 0; i < 24; i = i+1) begin
            repeat(100) @(posedge clk);
            clr_cmd_rdy = 1;
            @(posedge clk);
            clr_cmd_rdy = 0;

            repeat(100) @(posedge clk);
            send_resp = 1;
            @(posedge clk);
            send_resp = 0;

            repeat(100) @(posedge clk);
            clr_cmd_rdy = 1;
            @(posedge clk);
            clr_cmd_rdy = 0;

            repeat(100) @(posedge clk);
            send_resp = 1;
            @(posedge clk);
            send_resp = 0;

            repeat(100) @(posedge clk);
        end
        $stop;

    end

    always #5 clk = ~clk;
endmodule
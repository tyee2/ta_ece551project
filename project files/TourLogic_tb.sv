module TourLogic_tb();
    logic clk;
    logic rst_n;
    logic [2:0] x_start, y_start;
    logic go;
    logic [4:0] indx;
    logic [7:0] move;
    logic done;

    TourLogic iTL(.*);

    initial begin
        clk = 0;
        rst_n = 0;
        x_start = 0;
        y_start = 0;
        go = 0;
        indx = 0;

        @(posedge clk);
        @(negedge clk);
        rst_n = 1;
        go = 1;
        @(posedge clk);
        go = 0;

        wait4sig(done,10000000);

        x_start = 2;
        y_start = 2;
        go = 0;
        indx = 0;

        @(posedge clk);
        @(negedge clk);
        rst_n = 1;
        go = 1;
        @(posedge clk);
        go = 0;

        wait4sig(done,10000000);
        $display("TourLogic passes!");
        $stop;

    end

    always #5 clk = ~clk;

    always @(negedge iTL.init_xy, negedge iTL.mark) begin : disp
        integer x, y;
        for(y=4; y>=0; y--) begin
            $display("%2d %2d %2d %2d %2d\n",iTL.board[0][y],iTL.board[1][y],
            iTL.board[2][y],iTL.board[3][y],iTL.board[4][y]);
        end
        $display("-------------------------\n");
    end

    task automatic wait4sig(ref sig, input int clks2wait);
    fork
        begin: timeout
            repeat(clks2wait) @(posedge clk);
            $display("ERR: timed out waiting for sig in wait4sig");
            $stop();
        end
        begin
            @(posedge sig); // signal of interest asserted
            disable timeout;
        end
    join
endtask

endmodule
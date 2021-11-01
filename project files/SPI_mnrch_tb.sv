module SPI_mnrch_tb();

    logic clk, rst_n;
    logic wrt;
    logic [15:0] wt_data, rd_data;
    logic SS_n, SCLK, MOSI, MISO, done;
    logic INT;

    // instantiate SPI
    SPI_mnrch iM(
        .clk(clk),
        .rst_n(rst_n),
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .wrt(wrt),
        .wt_data(wt_data),
        .done(done),
        .rd_data(rd_data)
    );

    SPI_iNEMO1 iS(
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MISO(MISO),
        .MOSI(MOSI),
        .INT(INT)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        wrt = 1;
        wt_data = 16'h8Fxx;

        @(posedge clk);
        @(negedge clk); 
        rst_n = 1;
        @(posedge clk); 
        wrt = 0;

        @(posedge done) 
        if(rd_data[7:0] !== 8'h6A) begin
            $display("WHO_AM_I register did not return the correct value. Expected 6A, got %h", rd_data[7:0]);
            $stop();
        end

        wt_data = 16'hA6xx;

        @(posedge clk);
        @(negedge clk); 
        wrt = 1;
        @(posedge clk); 
        wrt = 0;

        @(posedge done) 

        wt_data = 16'hA7xx;

        @(posedge clk);
        @(negedge clk); 
        wrt = 1;
        @(posedge clk); 
        wrt = 0;

        @(posedge done) 

        $display("All tests passed!");
        $stop();
    end

    always #5 clk = ~clk;

endmodule
module SPI_mnrch_tb();

    reg clk,rst_n,wrt;
    reg [15:0] wt_data;
    wire [15:0] rd_data;
    wire SS_n,SCLK,MOSI,MISO,done;
    wire INT;

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
        clk=0;
        rst_n=0;
        wrt=1;
        wt_data=16'h8Fxx;

        @(posedge clk);
        @(negedge clk) rst_n=1;
        @(posedge clk) wrt=0;

        @(posedge done) 
        if(rd_data[7:0] !== 8'h6A) begin
            $display("The WHO_AM_I register was not read correctly");
            $stop();
        end

        $display("All tests passed!");
        $stop();
    end

    always #5 clk = ~clk;

endmodule
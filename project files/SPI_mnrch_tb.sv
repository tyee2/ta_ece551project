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
        wrt = 0;
        wt_data = 16'h8Fxx;

        @(posedge clk);
        @(negedge clk); 
        wrt = 1;
        rst_n = 1;
        @(posedge clk); 
        wrt = 0;

        wait4sig(done,100000);
        if(rd_data[7:0] !== 8'h6A) begin
            $display("WHO_AM_I register did not return the correct value. Expected 6A, got %h", rd_data[7:0]);
            $stop();
        end

        @(posedge clk);
		
        // INT config
        wt_data = 16'h0D02;

        @(posedge clk);
        @(negedge clk); 
        wrt = 1;
        @(posedge clk); 
        wrt = 0;

        wait4sig(done,100000);
        @(posedge clk);
        if(iS.NEMO_setup !== 1) begin
            $display("NEMO_setup was never asserted after configuring the INT register");
            $stop();
        end
		
        @(posedge INT);

        wt_data = 16'hA6xx;

        @(posedge clk);
        @(negedge clk); 
        wrt = 1;
        @(posedge clk); 
        wrt = 0;

        wait4sig(done,100000);
        if(INT !== 0) begin
            $display("INT should fall when reading A6");
            $stop();
        end

        wt_data = 16'hA7xx;

        @(posedge clk);
        @(negedge clk); 
        wrt = 1;
        @(posedge clk); 
        wrt = 0;

        @(posedge done);

        $display("All tests passed!");
        $stop();
    end

    always #5 clk = ~clk;

    `include "tb_tasks.sv"
endmodule
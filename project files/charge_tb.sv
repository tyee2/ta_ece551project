module charge_tb();

    logic clk;
    logic rst_n;
    logic go;
    logic piezo;
    logic piezo_n;

    charge #(.FAST_SIM(1)) iDUT(
        .*
    );

    initial begin
        clk = 0;
        rst_n = 0;
        go = 0;

        @(posedge clk);
        @(negedge clk);

        rst_n = 1;

        repeat(100) @(posedge clk);

        go = 1;
        @(posedge clk);
        go = 0;

        repeat(4000000) @(posedge clk);
        $stop;

    end

    always #5 clk = ~clk;

endmodule
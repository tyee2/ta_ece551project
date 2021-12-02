module reset_synch(
    input               clk,    // global clock, negedge
    input               RST_n,  // raw push button input
    output logic        rst_n   // synchronized reset output
);
    // internal signals
    logic rst_ff1;

    always_ff @(negedge clk, negedge RST_n)
        if(!RST_n) begin
            rst_ff1 <= 0;
            rst_n <= 0;
        end
        else begin
            rst_ff1 <= 1;
            rst_n <= rst_ff1;
        end

endmodule

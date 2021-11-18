module PB_release(
    input  clk,
    input  rst_n,
    input  PB,
    output released
);
    // internal signals
    logic PB_ff1, PB_ff2, PB_ff3;

    // double flop for metastability and flop once more for rise edge detection
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n) begin
            PB_ff1 <= 1;
            PB_ff2 <= 1;
            PB_ff3 <= 1;
        end
        else begin
            PB_ff1 <= PB;
            PB_ff2 <= PB_ff1;
            PB_ff3 <= PB_ff2;
        end

    assign released = ~PB_ff3 && PB_ff2;

endmodule
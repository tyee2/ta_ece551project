module D_term(
    input clk, rst_n,
    input signed [9:0] err_sat,
    input err_vld,
    output signed [12:0] D_term
);
    localparam D_COEFF = 6'h0B;
    logic signed [9:0] err_sat_ff1, prev_err, D_diff;
    logic signed [6:0] D_diff_sat;

    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            err_sat_ff1 <= 0;
            prev_err <= 0;
        end else if(err_vld) begin
            err_sat_ff1 <= err_sat;
            prev_err <= err_sat_ff1;
        end
    end // end prev. error datapath

    // current error - prev. error (proportion of difference)
    assign D_diff = err_sat - prev_err;
    
    // 10-bit to 7-bit saturation of difference
    assign D_diff_sat = (D_diff[9] && ~(&D_diff[8:6])) ? 7'h40 : 
                        (~D_diff[9] && |D_diff[8:6]) ? 7'h3F : D_diff[6:0];

    assign D_term = $signed(D_COEFF) * D_diff_sat;
    
endmodule
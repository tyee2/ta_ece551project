module P_term(
    input signed [11:0] error,
    output signed [13:0] P_term
);
    localparam P_COEFF = 5'h8;
    logic signed [9:0] err_sat;

    assign err_sat = (error[11] && ~(&error[10:9])) ? 10'h200 : // sat to most neg number
                     (~error[11] && |error[10:9]) ? 10'h1FF : // sat to most pos number
                     error[9:0]; // else, in range

    assign P_term = err_sat * $signed(P_COEFF);
endmodule
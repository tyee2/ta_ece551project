module PID(
    input                       clk,
    input                       rst_n,
    input                       moving,
    input                       err_vld,
    input        signed [11:0]  error,
    input               [9:0]   frwrd,      // only positive, saturating
    output logic signed [10:0]  lft_spd,
    output logic signed [10:0]  rght_spd
);
    //////////////////// internal signals ////////////////////
    localparam P_COEFF = 5'h8;
    localparam D_COEFF = 6'h0B;

    logic signed [13:0] P_term;
    logic        [8:0]  I_term;
    logic signed [12:0] D_term;
    logic signed [13:0] PID;
    logic        [10:0] zext_frwrd;
    logic signed [10:0] lft_frwrd;
    logic signed [10:0] rght_frwrd;
    logic signed [10:0] lft_sat;
    logic signed [10:0] rght_sat;

    // P_term signals //
    logic signed [9:0] err_sat;

    // I_term signals //
    logic ov;
    logic signed [14:0] err_sat_ext, err_int_accum, err_chk_integrator, nxt_integrator;
    logic signed [14:0] integrator;

    // D_term signals //
    logic signed [9:0] err_sat_ff1, prev_err, D_diff;
    logic signed [6:0] D_diff_sat;

    // saturate signed error to 10 bits
    assign err_sat = (error[11] && ~(&error[10:9])) ? 10'h200 : // sat to most neg number
                     (~error[11] && |error[10:9]) ? 10'h1FF : // sat to most pos number
                     error[9:0]; // else, in range

    //////////////////// PID terms ////////////////////
    // P_term //
    assign P_term = err_sat * $signed(P_COEFF);

    // I_term //
    // sign-extend 10-bit error to 15 bits, then accumulate.
    assign err_sat_ext = {{5{err_sat[9]}},err_sat};
    assign err_int_accum = err_sat_ext + integrator;
    
    // if MSBs of operands match, MSB of addition result should also match MSB of operand. otherwise overflow.
    assign ov = (~(integrator[14]^err_sat_ext[14])) && (err_int_accum[14] != integrator[14]);
    
    // error is accumulated if valid. otherwise it is frozen at previous value.
    assign err_chk_integrator = (~ov && err_vld) ? err_int_accum : integrator;
    
    // clear integrator if not moving.
    assign nxt_integrator = moving ? err_chk_integrator : 15'h0000;
    
    // infer integrator flop
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            integrator <= 15'h0000;
        else
            integrator <= nxt_integrator;
    end

    assign I_term = integrator[14:6];

    // D_term //
    // prev. error datapath: flop incoming error twice
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

    ////////////////////// PID datapath //////////////////////
    assign PID = P_term + {{5{I_term[8]}},I_term} + {D_term[12],D_term};
    assign zext_frwrd = {1'b0,frwrd}; // to 11 bits

    // unsaturated addition
    assign lft_frwrd = zext_frwrd + PID[13:3];
    assign rght_frwrd = zext_frwrd - PID[13:3];

    // 11 -> 11 bit positive saturation
    // zero-extended frwrd term is always positive
    // if MSBs of operands are both 0 but result flips, saturate to 3FF
    assign lft_sat = (~zext_frwrd[10] && ~PID[13]) ? lft_frwrd[10] : 0;
    assign rght_sat = (~zext_frwrd[10] && PID[13]) ? rght_frwrd[10] : 0;

    // saturated result, response is 0 if not moving
    assign lft_spd = moving ? ((lft_sat) ? 11'h3FF : lft_frwrd) : 0;
    assign rght_spd = moving ? ((rght_sat) ? 11'h3FF : rght_frwrd) : 0;

endmodule
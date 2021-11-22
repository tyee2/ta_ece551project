module cmd_proc #(
    parameter FAST_SIM = 1                      // speed up simulation when set
) 
(
    input                       clk,            // 50 MHz system clock
    input                       rst_n,          // active low async reset
    input               [15:0]  cmd,            // from UART_wrapper, contains 16-bit command
    input                       cmd_rdy,        // from UART_wrapper, asserted when cmd is ready
    input                       cal_done,       // gyro calibration done
    input                       heading_rdy,    // pulse 1 clock cycle for valid heading
    input                       lftIR,          // err_nudge +
    input                       cntrIR,         // line crossing
    input                       rghtIR,         // err_nudge -
    input        signed [11:0]  heading,        // gyro heading
    output logic signed [11:0]  error,          // to PID (heading - desired_heading)
    output logic                clr_cmd_rdy,    // to UART_wrapper, knocks down cmd_rdy
    output logic                send_resp,      // finished cmd, send response to UART_wrapper
    output logic                strt_cal,       // to inert_intf, start gyro calibration
    output logic        [9:0]   frwrd,          // forward speed
    output logic                moving,         // to inert_intf, yaw integration valid
    output logic                tour_go,        // to TourCmd, solve Knight's Tour
    output logic                fanfare_go      // to charge, starts fanfare
);
    ////////////////////////////// internal signals //////////////////////////////
    logic               cntr_ff;
    logic               cntr_rise;              // since cntrIR pulse can be many clocks in width
    logic               move_done;              // asserted when # of cntrIR pulses = 2*cmd[2:0]
    logic        [2:0]  num_squares;            // cmd[2:0] reg
    logic        [3:0]  num_crossings;          // # of cntrIR pulses
    logic signed [11:0] desired_heading;        // promote desired_heading to 12 bits
    logic signed [11:0] err_nudge;              // error correction term
    logic               max_spd;                // forward speed is max (&frwrd[9:8])

    /////////////////////////// SM outputs and states ////////////////////////////
    logic               move_cmd;                       // new move command issued
    logic               clr_frwrd;
    logic               dec_frwrd;
    logic               inc_frwrd;

    // state type enumeration
    typedef enum logic [2:0] { IDLE, CAL, UPDATE, MOVE, STOP } state_t;
	state_t state, nxt_state;

    /////////////////////////////// BEGIN datapath ///////////////////////////////
    /////////////////////////////// frwrd register ///////////////////////////////
    // assign larger increment/decrement in FAST_SIM to speed up simulation
    generate 
        if(FAST_SIM) begin
            always_ff @(posedge clk, negedge rst_n)
                if(!rst_n)
                    frwrd <= 10'h000;
                else if(clr_frwrd)
                    frwrd <= 10'h000;
                else if(heading_rdy)
                    // ramp up to max speed while move is not done
                    if(inc_frwrd && ~max_spd)
                        frwrd <= frwrd + 10'h020;
                    // ramp down until we stop when we reach last square in move
                    else if (dec_frwrd && |frwrd)
                        frwrd <= frwrd - 10'h040;
        end
        else begin
            always_ff @(posedge clk, negedge rst_n)
                if(!rst_n)
                    frwrd <= 10'h000;
                else if(clr_frwrd)
                    frwrd <= 10'h000;
                else if(heading_rdy)
                    // ramp up to max speed while move is not done
                    if(inc_frwrd && ~max_spd)
                        frwrd <= frwrd + 10'h004;
                    // ramp down until we stop when we reach last square in move
                    else if (dec_frwrd && |frwrd)
                        frwrd <= frwrd - 10'h008;
        end
    endgenerate

    assign max_spd = &frwrd[9:8];

    ////////////////////////////// counting squares //////////////////////////////
    always_ff @(posedge clk)
        if(move_cmd)
            num_squares <= cmd[2:0];

    always_ff @(posedge clk)
        if(move_cmd)
            num_crossings <= 0;
        else if(cntr_rise)
            num_crossings <= num_crossings + 1;

    // rising edge detector
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            cntr_ff <= 0;
        else
            cntr_ff <= cntrIR;

    assign cntr_rise = ~cntr_ff && cntrIR;
    assign move_done = {num_squares,1'b0} == num_crossings;

    /////////////////////////////// PID interface ////////////////////////////////
    always_ff @(posedge clk)
        if(move_cmd)
            if(~|cmd[11:4])
                desired_heading <= 12'h000;
            else
                desired_heading <= {cmd[11:4],4'hF};

    // assign larger err_nudge in FAST_SIM to speed up simulation
    generate
        if(FAST_SIM) begin
            assign err_nudge = lftIR ? 12'h1FF :
                               rghtIR ? 12'hE00 : 12'h000;
        end
        else begin
            assign err_nudge = lftIR ? 12'h5F :
                               rghtIR ? 12'hFA1 : 12'h000;
        end
    endgenerate

    assign error = heading - desired_heading + err_nudge;
    /////////////////////////////// END datapath /////////////////////////////////
    ////////////////////////////// state machine /////////////////////////////////
    // state register
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
    
    // state transition and output logic
    always_comb begin
        // default outputs
        nxt_state = state;
        clr_cmd_rdy = 0;
        send_resp = 0;
        strt_cal = 0;
        move_cmd = 0;
        moving = 0;
        clr_frwrd = 0;
        dec_frwrd = 0;
        inc_frwrd = 0;
        fanfare_go = 0;
        tour_go = 0;

        case(state)
            // IDLE: wait for cmd_rdy and transition to appropriate state
            default: begin
                if(cmd_rdy) begin
                    // immediately clear cmd_rdy
                    clr_cmd_rdy = 1;

                    // calibrate
                    if(cmd[15:12] == 4'b0000) begin
                        strt_cal = 1;
                        nxt_state = CAL;
                    end

                    // move (fanfare handled in move state)
                    else if(cmd[15:13] == 3'b001) begin
                        move_cmd = 1;
                        nxt_state = UPDATE;
                    end

                    // start tour (no response)
                    else if(cmd[15:12] == 4'b0100) begin
                        tour_go = 1;
                    end
                end
            end

            // wait for gyro to be calibrated
            CAL: begin
                if(cal_done) begin
                    send_resp = 1;
                    nxt_state = IDLE;
                end
            end

            // adjust to proper heading for error inside +/-12'h030
            UPDATE: begin
                moving = 1;
                clr_frwrd = 1;

                if(error > 12'shFD0 && error < 12'sh030)
                    nxt_state = MOVE;
            end

            // start moving once error is below threshold
            MOVE: begin
                moving = 1;
                inc_frwrd = 1;

                // ramp down at last square
                if(move_done) begin
                    nxt_state = STOP;
                    // play fanfare if last bit of opcode is set
                    if(cmd[12])
                        fanfare_go = 1;
                end
            end

            // slow down at end of move
            STOP: begin
                moving = 1;
                dec_frwrd = 1;

                if(frwrd == 10'h000) begin
                    send_resp = 1;
                    nxt_state = IDLE;
                end
            end

        endcase
    end
endmodule
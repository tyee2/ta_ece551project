module TourCmd(
    input                       clk,            // 50 MHz system clock
    input                       rst_n,          // active low async reset
    input                       start_tour,     // from done signal from TourLogic
    input      [7:0]            move,           // from TourLogic, encoded 1-hot move to perform
    input      [15:0]           cmd_UART,       // cmd from UART_wrapper
    input                       cmd_rdy_UART,   // cmd_rdy from UART_wrapper
    input                       clr_cmd_rdy,    // from cmd_proc (goes to UART_wrapper too)
    input                       send_resp,      // lets us know cmd_proc is done with command
    output reg [4:0]            mv_indx,        // "address" to access next move
    output     [15:0]           cmd,            // multiplexed cmd to cmd_proc
    output reg                  cmd_rdy,        // cmd_rdy signal to cmd_proc
    output     [7:0]            resp            // either 0xA5 (done) or 0x5A (in progress)
);
    ///////////////////////////// internal signals /////////////////////////////
    // cmd[11:4]
    localparam HEADING_NORTH = 8'h00;
    localparam HEADING_SOUTH = 8'h7F;
    localparam HEADING_EAST = 8'hBF;
    localparam HEADING_WEST = 8'h3F;

    logic [15:0] cmd_TC;                        // move command during tour 

    ////////////////////////// SM outputs and states ///////////////////////////
    logic        cmd_sel;                       // 0: UART, 1: TourCmd
    logic        done_mv;                       // asserted when L move is complete
    logic        mv1_en;                        // first move segment enable
    logic        mv2_en;                        // second move segment enable
    logic        send_cmd_SM;                   // one cycle delay for cmd_rdy
    logic        clr_mv_cnt;                    // clear move counter upon starting tour

    // state type enumeration
    typedef enum logic [2:0] { IDLE, MOVE_Y, WAIT_Y, MOVE_X, WAIT_X } state_t;
    state_t state, nxt_state;

    ///////////////////////////// begin datapath ///////////////////////////////
    // move counter
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            mv_indx <= 0;
        else if(clr_mv_cnt)
            mv_indx <= 0;
        else if(done_mv)
            mv_indx <= mv_indx + 1;

    // movement command flop, holds cmd when not enabled
    // same encoding as slides
    // [i]:  x   y
    // [0]: -1   2
    // [1]:  1   2
    // [2]:  1   1
    // [3]: -2  -1
    // [4]: -1  -2
    // [5]:  1  -2
    // [6]:  2  -1
    // [7]:  2   1
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            cmd_TC <= 16'h0;

        // first part of move (vertical)
        else if(mv1_en) begin
            if(move[0])
                cmd_TC <= {4'b0010,HEADING_NORTH,4'h2};
            else if(move[1])
                cmd_TC <= {4'b0010,HEADING_NORTH,4'h2};
            else if(move[2])
                cmd_TC <= {4'b0010,HEADING_NORTH,4'h1};
            else if(move[3])
                cmd_TC <= {4'b0010,HEADING_SOUTH,4'h1};
            else if(move[4])
                cmd_TC <= {4'b0010,HEADING_SOUTH,4'h2};
            else if(move[5])
                cmd_TC <= {4'b0010,HEADING_SOUTH,4'h2};
            else if(move[6])
                cmd_TC <= {4'b0010,HEADING_SOUTH,4'h1};
            else if(move[7])
                cmd_TC <= {4'b0010,HEADING_NORTH,4'h1};
        end

        // second part of move with fanfare (horizontal)
        else if(mv2_en) begin
            if(move[0])
                cmd_TC <= {4'b0011,HEADING_WEST,4'h1};
            else if(move[1])
                cmd_TC <= {4'b0011,HEADING_EAST,4'h1};
            else if(move[2])
                cmd_TC <= {4'b0011,HEADING_WEST,4'h2};
            else if(move[3])
                cmd_TC <= {4'b0011,HEADING_WEST,4'h2};
            else if(move[4])
                cmd_TC <= {4'b0011,HEADING_WEST,4'h1};
            else if(move[5])
                cmd_TC <= {4'b0011,HEADING_EAST,4'h1};
            else if(move[6])
                cmd_TC <= {4'b0011,HEADING_EAST,4'h2};
            else if(move[7])
                cmd_TC <= {4'b0011,HEADING_EAST,4'h2};
        end

    // flop to delay cmd_rdy one cycle
    always_ff @(posedge clk)
        cmd_rdy <= send_cmd_SM;

    assign cmd = cmd_sel ? cmd_TC : cmd_UART;
    ////////////////////////////// end datapath ////////////////////////////////
    ///////////////////////////// state machine ////////////////////////////////
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
        clr_mv_cnt = 0;
        cmd_sel = 0;
        send_cmd_SM = 0;
        done_mv = 0;
        mv1_en = 0;
        mv2_en = 0;

        case(state)
            // IDLE: wait for start_tour. mux select passes UART commands to cmd_proc.
            default: begin
                if(start_tour) begin
                    cmd_sel = 1;
                    clr_mv_cnt = 0;
                    nxt_state = MOVE_Y;
                end
            end

            // first move segment, no fanfare
            MOVE_Y: begin
                cmd_sel = 1;
                mv1_en = 1;
                if(clr_cmd_rdy)
                    nxt_state = WAIT_Y;
            end

            // wait until send_resp
            WAIT_Y: begin
                cmd_sel = 1;
                if(send_resp) begin
                    nxt_state = MOVE_X;
                end
            end

            // second move segment, play fanfare
            MOVE_X: begin
                cmd_sel = 1;
                mv2_en = 1;
                if(clr_cmd_rdy)
                    nxt_state = WAIT_X;
            end

            WAIT_X: begin
                cmd_sel = 1;
                // done with second move segment
                if(send_resp) begin
                    // check if last move else go back to second state
                    if(mv_indx == 5'b10111) begin
                        nxt_state = IDLE;
                    end
                    else begin
                        done_mv = 1;
                        nxt_state = MOVE_Y;
                    end
                end
            end
        endcase
    end

endmodule
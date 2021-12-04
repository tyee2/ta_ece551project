module TourLogic(
    input              clk,             // 50 MHz system clock
    input              rst_n,           // active low async reset
    input        [2:0] x_start,         // starting x position of Knight
    input        [2:0] y_start,         // starting y position of Knight
    input              go,              // from cmd_proc to SM to find solution to tour
    input        [4:0] indx,            // move index for replaying solution
    output       [7:0] move,            // one-hot encoding of move
    output logic       done
);
    ///////////////////////////// internal signals /////////////////////////////
    logic              board[0:4][0:4];     // 5x5 chessboard, tracks visited squares
    logic        [7:0] tried_moves[0:23];   // moves tried from this position
    logic        [7:0] poss_moves;          // possible moves at current position
    logic        [7:0] try;                 // one-hot encoded move to try
    logic        [4:0] curr_mv_indx;        // pointer of current move
    logic        [2:0] curr_x;              // current x position
    logic        [2:0] curr_y;              // current y position
    logic        [2:0] last_x;              // past x position
    logic        [2:0] last_y;              // past y position
    logic        [2:0] next_x;              // future x position
    logic        [2:0] next_y;              // future y position

    ////////////////////////// SM outputs and states ///////////////////////////
    logic       clr_board;                  // clear board and tried moves
    logic       init_xy;                    // mark starting position on board
    logic       mark;                       // movement has been made
    logic       update_poss;                // initial update possible moves at curr_pos
    logic       cur_poss;                   // same as above, but does not reset move pointer
    logic       inc_try;                    // advance to next move to try
    logic       unmark;                     // unmark tried move from curr_pos in backup
    logic       calc_done;                  // solution is found, delay done by 1 clock

    // state type enumeration
    typedef enum logic [2:0] { IDLE, INIT, POSSIBLE, MAKE_MOVE, BACKUP } state_t;
    state_t state, nxt_state;

    ///////////////////////////// begin datapath ///////////////////////////////
    // board flop
    always_ff @(posedge clk)
        // clear upon starting tour
        if(clr_board) begin
            for(int i = 0; i < 5; i = i+1) begin
                for(int j = 0; j < 5; j = j+1) begin
                    board[i][j] <= 0;
                end
            end
        end
        // mark initial position
        else if(init_xy)
            board[x_start][y_start] <= 1;
        // mark visited position
        else if(mark)
            board[next_x][next_y] <= 1;
        // unmark backed up move
        else if(unmark)
            board[curr_x][curr_y] <= 0;

    // move pointer
    always_ff @(posedge clk)
        if(clr_board)
            curr_mv_indx <= 0;
        else if(mark)
            curr_mv_indx <= curr_mv_indx + 1;
        else if(unmark)
            curr_mv_indx <= curr_mv_indx - 1;

    // board position update
    always_ff @(posedge clk)
        if(init_xy) begin
            curr_x <= x_start;
            curr_y <= y_start;
        end
        else if(mark) begin
            curr_x <= next_x;
            curr_y <= next_y;
        end
        else if(unmark) begin
            curr_x <= last_x;
            curr_y <= last_y;
        end

    // tried moves at current position
    always_ff @(posedge clk)
        if(mark)
            tried_moves[curr_mv_indx] <= try;

    // update possible moves upon entering square
    always_ff @(posedge clk)
        if(cur_poss || update_poss)
            poss_moves <= calc_poss(curr_x,curr_y);

    // set move to try
    always_ff @(posedge clk)
        if(update_poss)
            try <= 8'b0000_0001;
        else if(inc_try)
            try <= {try[6:0],1'b0};
        else if(unmark)
            try <= {tried_moves[curr_mv_indx-1][6:0],1'b0};

    // assert when solution found
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            done <= 0;
        else
            done <= calc_done;

    // future and past x,y coordinates
    assign next_x = curr_x + off_x(try);
    assign next_y = curr_y + off_y(try);
    assign last_x = curr_x - off_x(tried_moves[curr_mv_indx-1]);
    assign last_y = curr_y - off_y(tried_moves[curr_mv_indx-1]);

    assign move = tried_moves[indx];

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
        clr_board = 0;
        init_xy = 0;
        mark = 0;
        update_poss = 0;
        cur_poss = 0;
        inc_try = 0;
        unmark = 0;
        calc_done = 0;

        case(state)
            // IDLE: waiting for go
            default: begin
                if(go) begin
                    clr_board = 1;
                    nxt_state = INIT;
                end
            end

            // set up initial coordinates
            INIT: begin
                init_xy = 1;
                nxt_state = POSSIBLE;
            end

            // update current possible moves in poss_moves
            POSSIBLE: begin
                update_poss = 1;
                nxt_state = MAKE_MOVE;
            end

            // try moving and check for valid move, or backup if all tries exhausted
            MAKE_MOVE: begin
                cur_poss = 1;
                // try possible move and mark if next position is valid
                if((poss_moves & try) && (board[next_x][next_y] == 0)) begin
                    mark = 1;
                    // we are done if 24th move
                    if(curr_mv_indx == 5'd23) begin
                        calc_done = 1;
                        nxt_state = IDLE;
                    end
                    else begin
                        nxt_state = POSSIBLE;
                    end
                end
                // advance try to next one-hot encoded move
                else if(!try[7]) begin
                    inc_try = 1;
                end
                // else no more possible moves
                else begin
                    nxt_state = BACKUP;
                end
            end

            // back up a move
            BACKUP: begin
                unmark = 1;
                // check if we tried all of the previous possible moves
                if(tried_moves[curr_mv_indx-1] == 8'b1000_0000)
                    nxt_state = BACKUP;
                else
                    nxt_state = MAKE_MOVE;
            end

        endcase
    end
    /////////////////////////// helper functions ///////////////////////////////
    // movement encoding offsets, same encoding as slides
    // [i]:  x   y
    // [0]: -1   2
    // [1]:  1   2
    // [2]: -2   1
    // [3]: -2  -1
    // [4]: -1  -2
    // [5]:  1  -2
    // [6]:  2  -1
    // [7]:  2   1

    // calculate x offset based on encoded move
    function signed [2:0] off_x(input [7:0] mv);
        off_x = (mv == 8'b0000_0001 || mv == 8'b0001_0000) ? -3'd1 :
                (mv == 8'b0000_0010 || mv == 8'b0010_0000) ?  3'd1 :
                (mv == 8'b0000_0100 || mv == 8'b0000_1000) ? -3'd2 : 3'd2;
    endfunction

    // calculate y offset based on encoded move
    function signed [2:0] off_y(input [7:0] mv);
        off_y = (mv == 8'b0000_0001 || mv == 8'b0000_0010) ?  3'd2 :
                (mv == 8'b0000_0100 || mv == 8'b1000_0000) ?  3'd1 :
                (mv == 8'b0000_1000 || mv == 8'b0100_0000) ? -3'd1 : -3'd2;
    endfunction
    
    // find all possible moves at given x,y coordinate
    function [7:0] calc_poss(input [4:0] xx, yy);
        calc_poss[0] = (xx > 0 && yy < 3);
        calc_poss[1] = (xx < 4 && yy < 3);
        calc_poss[2] = (xx > 1 && yy < 4);
        calc_poss[3] = (xx > 1 && yy > 0);
        calc_poss[4] = (xx > 0 && yy > 1);
        calc_poss[5] = (xx < 4 && yy > 1);
        calc_poss[6] = (xx < 3 && yy > 0);
        calc_poss[7] = (xx < 3 && yy < 4);
    endfunction
endmodule
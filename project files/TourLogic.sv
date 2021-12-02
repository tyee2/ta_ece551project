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
    logic        [7:0] poss_moves[0:23];    // possible moves at current position
    logic        [7:0] try;                 // one-hot encoded move to try
    logic        [4:0] curr_mv_indx;        // pointer of current move
    logic signed [2:0] add_x;               // x offset
    logic signed [2:0] add_y;               // y offset
    // logic [5:0] curr_pos;
    logic        [2:0] curr_x;              // current x position
    logic        [2:0] curr_y;              // current y position
    logic        [2:0] last_x;              // past x position
    logic        [2:0] last_y;              // past y position
    logic        [2:0] next_x;              // future x position
    logic        [2:0] next_y;              // future y position

    ////////////////////////// SM outputs and states ///////////////////////////
    logic       clr_board;                     // clear board and tried moves
    logic       init_xy;                       // mark starting position on board
    logic       mark;                          // movement has been made
    logic       calc_poss;                     // update possible moves at curr_pos
    logic       adv_try;                       // advance to next move to try
    logic       unmark;                        // unmark tried move from curr_pos in backup

    // state type enumeration
    typedef enum logic [2:0] { IDLE, INIT, POSSIBLE, MAKE_MOVE, BACKUP } state_t;
    state_t state, nxt_state;

    ///////////////////////////// begin datapath ///////////////////////////////
    // movement encoding logic, same encoding as slides
    // [i]:  x   y
    // [0]: -1   2
    // [1]:  1   2
    // [2]: -2   1
    // [3]: -2  -1
    // [4]: -1  -2
    // [5]:  1  -2
    // [6]:  2  -1
    // [7]:  2   1
    assign add_x = (try == 8'b0000_0001 || try == 8'b0001_0000) ? -3'd1 :
                   (try == 8'b0000_0010 || try == 8'b0010_0000) ?  3'd1 :
                   (try == 8'b0000_0100 || try == 8'b0000_1000) ? -3'd2 :
                   (try == 8'b0100_0000 || try == 8'b1000_0000) ?  3'd2 : 0;

    assign add_y = (try == 8'b0000_0001 || try == 8'b0000_0010) ?  3'd2 :
                   (try == 8'b0000_0100 || try == 8'b1000_0000) ?  3'd1 :
                   (try == 8'b0000_1000 || try == 8'b0100_0000) ? -3'd1 : 
                   (try == 8'b0001_0000 || try == 8'b0010_0000) ? -3'd2 : 0;

    // board flop
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n) begin
            for(int i = 0; i < 5; i = i+1) begin
                for(int j = 0; j < 5; j = j+1) begin
                    board[i][j] <= 0;
                end
            end
        end
        // clear upon starting tour
        else if(clr_board) begin
            for(int i = 0; i < 5; i = i+1) begin
                for(int j = 0; j < 5; j = j+1) begin
                    board[i][j] <= 0;
                end
            end
        end
        // mark initial position
        else if(init_xy)
            board[x_start][y_start] <= 1;
        // unmark backed up move
        else if(unmark)
            board[curr_x][curr_y] <= 1;

    // move pointer
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            curr_mv_indx <= 0;
        else if(clr_board)
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

    always_ff @(posedge clk)
        if(mark)
            tried_moves[curr_mv_indx] <= try;

        

    ////////////////////////////// end datapath ////////////////////////////////
    ///////////////////////////// state machine ////////////////////////////////
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
    
    always_comb begin

    end
    /////////////////////////// helper functions ///////////////////////////////
    function [7:0] calc_possible(input [2:0] x, y);

    endfunction
endmodule
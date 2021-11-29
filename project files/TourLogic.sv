module TourLogic(
    input                   clk,            // 50 MHz system clock
    input                   rst_n,          // active low async reset
    input  [2:0]            x_start,        // starting x position of Knight
    input  [2:0]            y_start,        // starting y position of Knight
    input                   go,             // from cmd_proc to SM to find solution to tour
    input  [4:0]            indx,           // move index for replaying solution
    output [7:0]            move,           // one-hot encoding of move
);
    ///////////////////////////// internal signals /////////////////////////////
    

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

endmodule
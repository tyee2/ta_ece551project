module TourCmd(
    input                       clk,            // 50 MHz system clock
    input                       rst_n,          // active low async reset
    input                       start_tour,     // from done signal from TourLogic
    input      [7:0]            move,           // encoded 1-hot move to perform
    input      [15:0]           cmd_UART,       // cmd from UART_wrapper
    input                       cmd_rdy_UART,   // cmd_rdy from UART_wrapper
    input                       clr_cmd_rdy,    // from cmd_proc (goes to UART_wrapper too)
    input                       send_resp,      // lets us know cmd_proc is done with command
    output reg [4:0]            mv_indx,        // "address" to access next move
    output     [15:0]           cmd,            // multiplexed cmd to cmd_proc
    output                      cmd_rdy,        // cmd_rdy signal to cmd_proc
    output     [7:0]            resp            // either 0xA5 (done) or 0x5A (in progress)
);
    ///////////////////////////// internal signals /////////////////////////////
    

    
endmodule
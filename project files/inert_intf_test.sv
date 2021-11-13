module inert_intf_test #(
    parameter FAST_SIM = 0
)
(
    input               clk,
    input               RST_n,
    input               MISO,
    input               INT,
    output              MOSI,
    output              SCLK,
    output              SS_n,
    output [7:0]        LED
);
    ////////////////////// internal signals //////////////////////
    // reset_synch
    logic rst_n;

    // inert_intf
    logic cal_done, strt_cal, rdy;
    logic [11:0] heading;

    // state machine inputs and outputs
    logic sel;

    // state type enumeration
    typedef enum logic [1:0] {IDLE,CAL,DISP} state_t;
    state_t state, nxt_state;

    ///////////// instantiate interface and reset_synch /////////////
    reset_synch iRST(
        .*
    );

    inert_intf #(FAST_SIM) iINTF(
        .*,
        .rst_n(rst_n),
        .moving(1'b1),
        .lftIR(1'b0),
        .rghtIR(1'b0)
    );

    ////////////////////////// state machine //////////////////////////
    // state register
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            state <= IDLE;
        else 
            state <= nxt_state;
    
    // output and transition logic
    always_comb begin
        // default outputs and next state
        sel = 0;
        strt_cal = 0;
        nxt_state = state;

        case(state)
            IDLE: begin
                sel = 0;
                strt_cal = 1;
                nxt_state = CAL;
            end

            CAL: begin
                sel = 1;
                if(cal_done) begin
                    nxt_state = DISP;
                end
            end

            DISP: begin
                sel = 0;
            end
        endcase
    end

    assign LED = sel ? 8'hA5 : heading[11:4];

endmodule

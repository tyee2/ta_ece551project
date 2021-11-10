	input clk,
	input rst_n,
	input strt_cal,         // from cmd_proc
	input INT,              // from inertial sensor, needs double flop
	input moving,
	input lftIR,            // left guardrail
	input rghtIR,           // right guardrail
	input MISO,             // from inertial sensor
	output cal_done,
	output rdy,
	output signed [11:0] heading,
	output SS_n,
	output SCLK,
	output MOSI
);
#(
    parameter FAST_SIM = 1; // set to 1 to speed up simulation
);
    ////////////////////// declare enum state type ///////////////////////
    typedef enum reg [2:0] {INIT1, INIT2, INIT3, WAIT_INT_RDY, RD_YAWL, RD_YAWH} state_t;
    state_t state, nxt_state;

    ////////////////////////////// SM outputs /////////////////////////////
    logic INT_en_init, gyro_init, round_gyro_init, st_yawL, st_yawH;
    logic wrt, C_Y_L, C_Y_H, yaw_rt_rdy, vld;


    /////////////////////////// internal signals //////////////////////////
    logic signed [15:0] yaw_rt;	// feeds inertial_integrator

    logic [15:0] cmd;
    assign cmd = (INT_en_init) ? 16'h0D02 :
                (gyro_init) ? 16'h1160 : 
                (round_gyro_init) ? 16'h1440 : 
                (st_yawL) ? 16'hA600 : 
                (st_yawH) ? 16'hA700 :
                16'h0000;

    ////////////////////////// internal registers /////////////////////////
    logic [7:0] yawL, yawH;
    logic INT_ff1, INT_ff2;
    logic [15:0] timer;

    // double flop of INT
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n) begin
            INT_ff1 <= 0;
            INT_ff2 <= 0;
        end 
		else begin
            INT_ff1 <= INT;
            INT_ff2 <= INT_ff1;
        end
   
    // 16-bit counter for SM
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            timer <= 0;
        else
            timer <= timer + 1;
  
    // holding register for yawL
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            yawL <= 0;
        else if(C_Y_L)
            yawL <= rd_data[7:0];

	// holding register for yawH
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            yawH <= 0;
        else if(C_Y_H)
            yawH <= rd_data[7:0];

    // delay vld one cycle when data is actually valid
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            vld <= 0;
        else
            vld <= yaw_rt_rdy;

  
    ////////////// instantiate SPI interface and integrator //////////////
    SPI_mnrch iSPI(
		.clk(clk),
		.rst_n(rst_n),
		.SS_n(SS_n),
		.SCLK(SCLK),
        .MISO(MISO),
		.MOSI(MOSI),
		.wrt(wrt),
		.done(done),
		.rd_data(rd_data),
		.wt_data(cmd)
	);
	
	// integrates angular rate readings to form desired heading
    inertial_integrator #(FAST_SIM) iINT(
        .clk(clk),
        .rst_n(rst_n),
        .strt_cal(strt_cal),
        .vld(vld),
        .rdy(rdy),
        .cal_done(cal_done),
        .yaw_rt(yaw_rt),
        .moving(moving),
        .lftIR(lftIR),
        .rghtIR(rghtIR),
        .heading(heading)
	);

    ////////////////////////////// state machine /////////////////////////
    // state register
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            state <= INIT1;
        else
            state <= nxt_state;

    // state transition and output logic
    always_comb begin
    // default outputs
    nxt_state = state;
    wrt = 0;
    INT_en_init = 0;
    gyro_init = 0;
    round_gyro_init = 0;
    yaw_rt_rdy = 0;
	st_yawL = 0;
	st_yawH = 0;
	C_Y_L = 0;
	C_Y_H = 0;

    case(state)
        INIT1: begin
            INT_en_init = 1;
            if(&timer) begin
                wrt = 1;
                nxt_state = INIT2;
            end
        end

        INIT2: begin
            gyro_init = 1;
            if(done) begin
                wrt = 1;
                nxt_state = INIT3;
            end
        end

        INIT3: begin
            round_gyro_init = 1;
            if(done) begin
                wrt = 1;
                nxt_state = WAIT_INT_RDY;
            end
        end

        default: begin // WAIT_INT_RDY
		    st_yawL = 1;
            if(INT_ff2) begin
			    wrt = 1;
                nxt_state = RD_YAWL;
            end
        end

        RD_YAWL: begin
            st_yawH = 1;
            if(done) begin
                wrt = 1;
                C_Y_L = 1;
                nxt_state = RD_YAWH;
            end
        end

        RD_YAWH: begin
            
            if(done) begin
		        C_Y_H = 1;
                nxt_state = WAIT_INT_RDY;
                yaw_rt_rdy = 1;
		    end
        end


    endcase
    end
  
endmodule
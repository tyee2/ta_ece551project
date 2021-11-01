module inert_intf(clk,rst_n,ptch,roll,yaw,strt_cal,cal_done,vld,SS_n,SCLK,
                  MOSI,MISO,INT);
				  
  parameter FAST_SIM = 1;		// used to accelerate simulation
 
  input clk, rst_n;
  input MISO;					// SPI input from inertial sensor
  input INT;					// goes high when measurement ready
  input strt_cal;				// from comand config.  Indicates we should start calibration
  
  output signed [15:0] ptch,roll,yaw;	// fusion corrected angles
  output cal_done;						// indicates calibration is done
  output reg vld;						// goes high for 1 clock when new outputs available
  output SS_n,SCLK,MOSI;				// SPI outputs

  ////////////////////////////////////////////
  // Declare any needed internal registers //
  //////////////////////////////////////////
  // << holding registers, timer, double flop of INT, ...>>
   logic [7:0] yawL, yawH;
   logic INT_ff1, INT_ff2;
   logic [15:0] timer;

   // double flop of INT
   always_ff @(posedge clk, negedge rst_n)
    if(!rst_n) begin
      INT_ff1 <= 0;
      INT_ff2 <= 0;
    end else begin
      INT_ff1 <= INT;
      INT_ff2 <= INT_ff1;
    end
   
   // 16-bit counter for SM
   always_ff @(posedge clk, negedge rst_n)
    if(!rst_n)
      timer <= 0;
    else
      timer <= timer + 1;
  

  //////////////////////////////////////
  // Outputs of SM are of type logic //
  ////////////////////////////////////
  // << declare all the output signals of your SM >>
  logic wrt, st_yawL, st_yawH, yaw_rt_rdy;


  //////////////////////////////////////////////////////////////
  // Declare any needed internal signals that connect blocks //
  ////////////////////////////////////////////////////////////
  wire signed [15:0] ptch_rt,roll_rt,yaw_rt;	// feeds inertial_integrator
  wire signed [15:0] ax,ay;						// accel data to inertial_integrator
  // << might need a few more >>
  
  
  ///////////////////////////////////////
  // Create enumerated type for state //
  /////////////////////////////////////
  // << declare your states and state register >>
  typedef enum reg [2:0] {INIT1, INIT2, INT_RDY, RD_YAWL, RD_YAWH} state_t;
  state_t state, nxt_state;
  
  ////////////////////////////////////////////////////////////
  // Instantiate SPI monarch for Inertial Sensor interface //
  //////////////////////////////////////////////////////////
  SPI_mnrch iSPI(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),
                 .wrt(wrt),.done(done),.rd_data(inert_data),.wt_data(cmd));
				  
  ////////////////////////////////////////////////////////////////////
  // Instantiate Angle Engine that takes in angular rate readings  //
  // and acceleration info and produces ptch,roll, & yaw readings //
  /////////////////////////////////////////////////////////////////
  inertial_integrator #(FAST_SIM) iINT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal), .cal_done(cal_done),
                                       .vld(vld), .ptch_rt(ptch_rt), .roll_rt(roll_rt), .yaw_rt(yaw_rt), .ax(ax),
						               .ay(ay), .ptch(ptch), .roll(roll), .yaw(yaw));
	

  //<< Rest is up to you >>
  ////////// state machine //////////
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

    case(state)
      INIT1: 
        if(&timer) begin
          wrt = 1;
          nxt_state = INIT2;
        end

      INIT2: 
        if(&timer[9:0]) begin
          wrt = 1;
          nxt_state = INT_RDY;
        end

      INT_RDY:

    endcase
  end
  
endmodule
	  
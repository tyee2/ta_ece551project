module PID_tb();

    // DUT signals //
    logic clk, rst_n;
    logic moving;
    logic err_vld;
    logic signed [11:0] error;
    logic [9:0] frwrd;
    logic [10:0] lft_spd;
    logic [10:0] rght_spd;

    // stimulus vectors //
    logic [24:0] stim_mem[0:1999];
    logic [21:0] resp_mem[0:1999];
    logic [24:0] stim;
    logic [21:0] resp;

    // response vectors //
    logic [10:0] lft_resp;
    logic [10:0] rght_resp;

    PID iDUT(
        .clk(clk), 
        .rst_n(rst_n), 
        .moving(moving), 
        .err_vld(err_vld), 
        .error(error), 
        .frwrd(frwrd), 
        .lft_spd(lft_spd), 
        .rght_spd(rght_spd)
    );

    initial begin
        $readmemh("PID_stim.hex",stim_mem);
        $readmemh("PID_resp.hex",resp_mem);

        clk = 0;

        for(int i = 0; i < 2000; i++) begin : test_loop
            stim = stim_mem[i];
            resp = resp_mem[i];

            // feed stimuli from file //
            rst_n = stim[24];
            moving = stim[23];
            err_vld = stim[22];
            error = stim[21:10];
            frwrd = stim[9:0];

            // feed response from file //
            lft_resp = resp[21:11];
            rght_resp = resp[10:0];

            @(posedge clk);
            #1;

            // compare expected response to DUT output //
            if(lft_spd !== lft_resp) begin
                $display("LEFT TEST %d failed. expected %h, got %h", i, lft_resp, lft_spd);
                $stop;
            end
            if(rght_spd !== rght_resp) begin
                $display("RIGHT TEST %d failed. expected %h, got %h", i, rght_resp, rght_spd);
                $stop;
            end
            
            $display("TEST %d passed.", i);
            
        end : test_loop

        $display("All tests passed.");
        $stop;
    end

    always #5 clk = ~clk;
endmodule
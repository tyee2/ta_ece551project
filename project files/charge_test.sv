module charge_test(
    input  clk,
    input  RST_n,
    input  GO,
    output piezo,
    output piezo_n
);
    // internal signals
    logic rst_n, go;

    // instantiate test modules
    charge #(.FAST_SIM(0)) iCH(
        .clk(clk),
        .rst_n(rst_n),
        .go(go),
        .piezo(piezo),
        .piezo_n(piezo_n)
    );

    PB_release iPB(
        .clk(clk),
        .rst_n(rst_n),
        .PB(GO),
        .released(go)
    );

    reset_synch iRST(
        .clk(clk),
        .RST_n(RST_n),
        .rst_n(rst_n)
    );
    
endmodule
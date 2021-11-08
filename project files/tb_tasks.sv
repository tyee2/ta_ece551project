task automatic wait4sig(ref sig, input int clks2wait);
    fork
        begin: timeout
            repeat(clks2wait) @(posedge clk);
            $display("ERR: timed out waiting for sig in wait4sig");
            $stop();
        end
        begin
            @(posedge sig); // signal of interest asserted
            disable timeout;
        end
    join
endtask


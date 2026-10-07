

`timescale 1ns/1ps

import fifo_pkg::*;

module fifo_tb_top;

    
    localparam int unsigned DATA_WIDTH = 8;
    localparam int unsigned DEPTH      = 16;

    bit clk = 0;
    always #5 clk = ~clk;

 
    fifo_if #(DATA_WIDTH) intf(clk);

   
    fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH)
    ) dut (
        .clk     (intf.clk),
        .rst_n   (intf.rst_n),
        .wr_en   (intf.wr_en),
        .rd_en   (intf.rd_en),
        .wr_data (intf.wr_data),
        .rd_data (intf.rd_data),
        .full    (intf.full),
        .empty   (intf.empty_o)
    );

    initial begin
        fifo_test #(DATA_WIDTH, DEPTH) test;

        $dumpfile("dump.vcd");
        $dumpvars(0, fifo_tb_top);

        test = new(intf, 300);
        test.run();

        $finish;
    end

endmodule

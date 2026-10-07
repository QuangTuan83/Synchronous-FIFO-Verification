interface fifo_if #(
    parameter int unsigned DATA_WIDTH = 8
) (
    input logic clk
);

    logic                  rst_n;
    logic                  wr_en;
    logic                  rd_en;
    logic [DATA_WIDTH-1:0] wr_data;

    logic [DATA_WIDTH-1:0] rd_data;
    logic                  full;
    logic                  empty_o;

    // Clocking block cho Driver
    clocking driver_cb @(posedge clk);
        default input #1step output #1ns;

        output rst_n;
        output wr_en;
        output rd_en;
        output wr_data;

        input  full;
        input  empty_o;
        input  rd_data;
    endclocking

    // Clocking block cho Monitor (chỉ lấy mẫu thụ động)
    clocking monitor_cb @(posedge clk);
        default input #1step;

        input rst_n;
        input wr_en;
        input rd_en;
        input wr_data;
        input rd_data;
        input full;
        input empty_o;
    endclocking

    modport DRV (clocking driver_cb, input clk);
    modport MON (clocking monitor_cb, input clk);

endinterface
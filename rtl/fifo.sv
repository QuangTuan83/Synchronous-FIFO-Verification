module fifo #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DEPTH      = 16
) (
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  wr_en,
    input  logic                  rd_en,

    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic [DATA_WIDTH-1:0] rd_data,

    output logic                  full,
    output logic                  empty
);

    //widths
    localparam int unsigned PTR_WIDTH   =   (DEPTH <= 1) ? 1 : $clog2(DEPTH);
    localparam int unsigned COUNT_WIDTH = $clog2(DEPTH + 1);

    localparam logic [PTR_WIDTH-1:0] LAST_ADDR     =  PTR_WIDTH'(DEPTH - 1);

    localparam logic [COUNT_WIDTH-1:0] DEPTH_COUNT =  COUNT_WIDTH'(DEPTH);

    // Parameter guards
    initial begin
        if (DATA_WIDTH < 1) $fatal(1, "fifo: DATA_WIDTH must be >= 1, got %0d", DATA_WIDTH);
        if (DEPTH < 1) $fatal(1, "fifo: DEPTH must be >= 1, got %0d", DEPTH);
    end

    // Storage and internal state
    logic [DATA_WIDTH-1:0]  mem [0:DEPTH-1];

    logic [PTR_WIDTH-1:0]   wr_ptr;
    logic [PTR_WIDTH-1:0]   rd_ptr;
    logic [COUNT_WIDTH-1:0] count;

    logic wr_acpt;
    logic rd_acpt;

    // Status flags
    assign full  = (count == DEPTH_COUNT);
    assign empty = (count == '0);

    // Acceptance logic
    assign wr_acpt = wr_en && !full;
    assign rd_acpt = rd_en && !empty;

    // Sequential updates
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr  <= '0;
            rd_ptr  <= '0;
            count   <= '0;
            rd_data <= '0;
        end
        else begin
            // Accepted write
            if (wr_acpt) begin
                mem[wr_ptr] <= wr_data;

                if (wr_ptr == LAST_ADDR)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            // Accepted read
            if (rd_acpt) begin
                rd_data <= mem[rd_ptr];

                if (rd_ptr == LAST_ADDR)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            // Occupancy update
            case ({wr_acpt, rd_acpt})
                2'b10:   count <= count + 1'b1;
                2'b01:   count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
bind fifo fifo_sva #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
) u_fifo_sva (
    .*,
    .wr_ptr(wr_ptr),
    .rd_ptr(rd_ptr),
    .count (count)
);

module fifo_sva #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DEPTH      = 16,
    localparam int unsigned PTR_WIDTH   = (DEPTH <= 1) ? 1 : $clog2(DEPTH),
    localparam int unsigned COUNT_WIDTH = $clog2(DEPTH + 1)
) (
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   wr_en,
    input  logic                   rd_en,
    input  logic [DATA_WIDTH-1:0]  wr_data,
    input  logic [DATA_WIDTH-1:0]  rd_data,
    input  logic                   full,
    input  logic                   empty,
    // White-box internal signals connected from RTL fifo.sv
    input  logic [PTR_WIDTH-1:0]   wr_ptr,
    input  logic [PTR_WIDTH-1:0]   rd_ptr,
    input  logic [COUNT_WIDTH-1:0] count
);

    // -------------------------------------------------------------
    // Helper Parameters & Accepted Transaction Signals
    // -------------------------------------------------------------
    localparam logic [COUNT_WIDTH-1:0] DEPTH_COUNT = COUNT_WIDTH'(DEPTH);
    localparam logic [PTR_WIDTH-1:0]   LAST_ADDR   = PTR_WIDTH'(DEPTH - 1);

    wire wr_take = wr_en && !full;
    wire rd_take = rd_en && !empty;


    // =============================================================
    // SECTION 1: Synchronous Reset Effect
    // =============================================================

    // 1.1: Verify synchronous reset initializes all state registers on the next cycle
    // Note: Does NOT use disable iff because this assertion must evaluate during reset.
    assert_sync_reset_effect: assert property (
        @(posedge clk) (rst_n == 1'b0) |=> (count   == '0   &&
                                            empty   == 1'b1 &&
                                            full    == 1'b0 &&
                                            rd_ptr  == '0   &&
                                            wr_ptr  == '0   &&
                                            rd_data == '0)
    ) else $error("ERROR: Synchronous reset failed to initialize FIFO state!");


    // =============================================================
    // SECTION 2: Protocol Black-box Assertions & Flags Consistency
    // =============================================================

    // 2.1: Full flag must hold when no read operation occurs
    assert_full_hold: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (full && !rd_en) |=> full
    ) else $error("ERROR: Full flag failed to hold when no read operation occurs!");

    // 2.2: Full flag must release on successful read operation
    assert_full_release: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (full && rd_en) |=> !full
    ) else $error("ERROR: Full flag failed to release on successful read operation!");

    // 2.3: Empty flag must hold when no write operation occurs
    assert_empty_hold: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (empty && !wr_en) |=> empty
    ) else $error("ERROR: Empty flag failed to hold when no write operation occurs!");

    // 2.4: Empty flag must release on successful write operation
    assert_empty_release: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (empty && wr_en) |=> !empty
    ) else $error("ERROR: Empty flag failed to release on successful write operation!");

    // 2.5: Absolute consistency between Full flag and count == DEPTH
    assert_full_flag_consistent: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (full == (count == DEPTH_COUNT))
    ) else $error("ERROR: Full flag inconsistent with count! full=%b, count=%0d, DEPTH=%0d", full, count, DEPTH);

    // 2.6: Absolute consistency between Empty flag and count == 0
    assert_empty_flag_consistent: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (empty == (count == '0))
    ) else $error("ERROR: Empty flag inconsistent with count! empty=%b, count=%0d", empty, count);


    // =============================================================
    // SECTION 3: Exact State-Transition Assertions
    // =============================================================

    // 3.1: Accepted write only -> count increments by 1
    assert_count_wr_only: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (wr_take && !rd_take) |=> (count == $past(count) + 1'b1)
    ) else $error("ERROR: Count failed to increment on accepted write only!");

    // 3.2: Accepted read only -> count decrements by 1
    assert_count_rd_only: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (!wr_take && rd_take) |=> (count == $past(count) - 1'b1)
    ) else $error("ERROR: Count failed to decrement on accepted read only!");

    // 3.3: Simultaneous accepted read and write -> count holds value
    assert_count_simult: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (wr_take && rd_take) |=> $stable(count)
    ) else $error("ERROR: Count failed to hold on simultaneous accepted R/W!");

    // 3.4: No accepted operation (idle/stall) -> count holds value
    assert_count_idle: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (!wr_take && !rd_take) |=> $stable(count)
    ) else $error("ERROR: Count failed to hold on idle (no accepted operation)!");

    // 3.5: Advance or wrap wr_ptr on accepted write
    assert_wr_ptr_advance: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        wr_take |=> (wr_ptr == (($past(wr_ptr) == LAST_ADDR) ? '0 : $past(wr_ptr) + 1'b1))
    ) else $error("ERROR: Write pointer failed to advance or wrap on accepted write!");

    // 3.6: Hold wr_ptr when no accepted write occurs
    assert_wr_ptr_hold: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        !wr_take |=> $stable(wr_ptr)
    ) else $error("ERROR: Write pointer failed to hold when no accepted write occurs!");

    // 3.7: Advance or wrap rd_ptr on accepted read
    assert_rd_ptr_advance: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        rd_take |=> (rd_ptr == (($past(rd_ptr) == LAST_ADDR) ? '0 : $past(rd_ptr) + 1'b1))
    ) else $error("ERROR: Read pointer failed to advance or wrap on accepted read!");

    // 3.8: Hold rd_ptr when no accepted read occurs
    assert_rd_ptr_hold: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        !rd_take |=> $stable(rd_ptr)
    ) else $error("ERROR: Read pointer failed to hold when no accepted read occurs!");

    // 3.9: Unified transition formula for count across all operations
    assert_count_unified: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        $past(rst_n) |-> (count == $past(count) + $past(wr_take) - $past(rd_take))
    ) else $error("ERROR: Count failed to follow unified transition formula!");


    // =============================================================
    // SECTION 4: Structural Invariants & Boundary Safety
    // =============================================================

    // 4.1: Write pointer must strictly remain within valid address range [0 : DEPTH-1]
    assert_wr_ptr_range: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (wr_ptr < DEPTH_COUNT)
    ) else $error("ERROR: Write pointer out of range! wr_ptr=%0d, DEPTH=%0d", wr_ptr, DEPTH);

    // 4.2: Read pointer must strictly remain within valid address range [0 : DEPTH-1]
    assert_rd_ptr_range: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (rd_ptr < DEPTH_COUNT)
    ) else $error("ERROR: Read pointer out of range! rd_ptr=%0d, DEPTH=%0d", rd_ptr, DEPTH);

    // 4.3: Occupancy count must never exceed FIFO DEPTH
    assert_occupancy_bound: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (count <= DEPTH_COUNT)
    ) else $error("ERROR: Occupancy out of bounds! count=%0d, DEPTH=%0d", count, DEPTH);

    // 4.4: Underflow protection: Read while empty must not alter rd_ptr or rd_data
    assert_underflow_protection: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (empty && rd_en) |=> ($stable(rd_ptr) && $stable(rd_data))
    ) else $error("ERROR: Underflow protection failed! Read pointer or data changed on read while empty!");

    // 4.5: Overflow protection: Write while full must not alter wr_ptr
    assert_overflow_protection: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (full && wr_en) |=> $stable(wr_ptr)
    ) else $error("ERROR: Overflow protection failed! Write pointer changed on write while full!");

    // 4.6: Circular buffer mathematical invariant: Pointer distance modulo DEPTH == count modulo DEPTH
    // Note: Cannot distinguish full from empty (both count%DEPTH==0); covered by 2.5, 2.6, 4.3.
    assert_ptr_count_consistency: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        ((int'(wr_ptr) + DEPTH - int'(rd_ptr)) % DEPTH == int'(count) % DEPTH)
    ) else $error("ERROR: Circular buffer invariant mismatch! wr_ptr=%0d, rd_ptr=%0d, count=%0d", wr_ptr, rd_ptr, count);

    // 4.7: Read data hold when no accepted read occurs
    assert_rd_data_hold: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        !rd_take |=> $stable(rd_data)
    ) else $error("ERROR: Read data changed without accepted read operation!");


    // =============================================================
    // SECTION 5: X/Z State Guards
    // Note: Data ordering and integrity are strictly owned by Scoreboard.
    // =============================================================

    // 5.1: Input control signals wr_en and rd_en must never float to X/Z
    assert_in_ctrl_known: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        !$isunknown({wr_en, rd_en})
    ) else $error("ERROR: Input control signals wr_en or rd_en are unknown (X/Z)!");

    // 5.2: Write data must never be X/Z during valid accepted write
    assert_wr_data_known: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        (wr_en && !full) |-> !$isunknown(wr_data)
    ) else $error("ERROR: Write data is unknown (X/Z) during valid write operation!");

    // 5.3: Status flags and count must never float to X/Z
    assert_status_count_known: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        !$isunknown({full, empty, count})
    ) else $error("ERROR: Status flags or count are unknown (X/Z)!");

    // 5.4: Internal pointers wr_ptr and rd_ptr must never float to X/Z
    assert_ptrs_known: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        !$isunknown({wr_ptr, rd_ptr})
    ) else $error("ERROR: Write or read pointer is unknown (X/Z)!");

    // 5.5: Read data must be known after accepted read or following reset
    assert_rd_data_known: assert property (
        @(posedge clk) disable iff (rst_n !== 1'b1)
        ($past(rd_en && !empty) || $past(!rst_n)) |-> !$isunknown(rd_data)
    ) else $error("ERROR: Read data is unknown (X/Z) after valid read or reset!");

endmodule

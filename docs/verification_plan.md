# FIFO Verification Plan

Verification plan for the single-clock synchronous FIFO in `rtl/fifo.sv`.

## What to check

- Reset: pointers and count go to zero, `empty = 1`, `full = 0`.
- Ordering: data comes out in the same order it went in.
- Flags: `empty` is high when the FIFO holds 0 entries, `full` when it holds `DEPTH`.
- Overflow: a write while full is ignored and the stored data is not changed.
- Underflow: a read while empty is ignored and `rd_data` is not changed.
- Read and write in the same cycle: count and ordering stay correct, including when the FIFO is full or empty.
- Pointer wrap-around: the run is long enough for both pointers to wrap past the last address.

## How

The testbench is class-based (generator, driver, monitor, reference model, scoreboard), without UVM.

Stimulus is constrained-random `wr_en` / `rd_en` with weights, so the FIFO reaches both full and empty instead of staying in the middle.

The reference model is a SystemVerilog queue. It is pushed on every accepted write and popped on every accepted read. The scoreboard compares the popped value with `rd_data` (which is registered, so it shows up one cycle after the read) and checks `full` / `empty` against the queue size.

Coverage is a covergroup on `wr_en`, `rd_en`, `full`, `empty`, with crosses `wr_en x full`, `rd_en x empty` and `wr_en x rd_en`. It is used to confirm that overflow, underflow and simultaneous read/write actually happened in simulation.

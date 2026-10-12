# Sync FIFO Verification Plan

DUT: `rtl/fifo.sv`, a single-clock synchronous FIFO (8-bit data, depth 16, active-low sync reset `rst_n`). `rd_data` is registered, so read data shows up one cycle after `rd_en`. A write while full or a read while empty is ignored.

## What to check

- Reset puts pointers, `count`, flags, and `rd_data` back to their defaults
- Data comes out in the same order it went in, nothing lost or duplicated
- `full` is high when `count == DEPTH`, `empty` is high when `count == 0`
- Overflow (write when full) and underflow (read when empty) are ignored
- Simultaneous read and write works when empty, full, and in between
- Pointers wrap from `DEPTH-1` back to `0`

## Testbench

Class-based SystemVerilog. The generator feeds the driver, which drives the DUT. The monitor watches the interface and sends each transaction to the scoreboard and the coverage collector. The scoreboard compares `rd_data`, `full`, and `empty` against a reference model, with the 1-cycle read latency taken into account. Clocking blocks avoid races, and a 10,000-cycle watchdog.

## Tests
1. **Sanity:** reset, then write and read back `00`, `FF`, `55`, `AA`.
2. **Corner cases:** write 24 items into an empty FIFO (overflow), read 24 from a full one (underflow), fill and drain 16 items 3 times 
3. **Random:** 300 transactions with `wr_en` at 60% and `rd_en` at 50%.

## Assertions

Checkers are in `fifo_sva` and attached with `bind`. 
With `wr_take = wr_en && !full` and `rd_take = rd_en && !empty`:

- Reset brings back to default
- `full` and `empty` always match `count` 
- `wr_take == wr_en && !full`, `rd_take == rd_en && !empty`
- Pointers advance on a successful write/read, wrap at the end, and hold
- Overflow leaves `wr_ptr` alone, underflow leaves `rd_ptr` and `rd_data` alone
- `full`, `empty`, and `count` are never `X` or `Z` (preventing simulation hangs)

## Coverage
- **Functional:** write/read activity, `full`/`empty` levels and transitions, data corner values, write x read cross, write while full, read while empty.
- **Code:** statement, branch, condition, and toggle on `fifo.sv` via `xelab -cc_type sbct`. Only the parameter checks in the `initial` block may stay uncovered.


## Pass criteria

A run passes if there are no compile errors, no watchdog timeout, `Total errors : 0` in the scoreboard, no assertion failures, 100% functional coverage, and 100% statement and branch coverage (apart from the exception above).
if there are not any failures, the run is considered a PASS.

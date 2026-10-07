# Synchronous FIFO Verification

Class-based SystemVerilog testbench for a single-clock synchronous FIFO (`rtl/fifo.sv`), simulated with Vivado XSIM 2025.2. 

The FIFO has `DATA_WIDTH` (default 8) and `DEPTH` (default 16) parameters. A write is accepted when `wr_en && !full`, a read when `rd_en && !empty`. `rd_data` is registered.

The testbench has a generator, driver, monitor, reference model, scoreboard and a coverage collector. The scoreboard compares `rd_data`, `full` and `empty` against a queue-based reference model.

## Run

```bash
make compile
make elaborate
make sim                 # 300 random transactions
make sim SEED=12345
make wave
make regression          # 5 seeds
make clean
```

## Structure

```
.
├── Makefile
├── README.md
├── docs
│   ├── img
│   │   └── wave_overview.png
│   └── verification_plan.md
├── filelists
│   └── tb.f
├── rtl
│   └── fifo.sv
├── scripts
│   └── regression.py
└── tb
    ├── fifo_coverage.sv
    ├── fifo_driver.sv
    ├── fifo_generator.sv
    ├── fifo_if.sv
    ├── fifo_monitor.sv
    ├── fifo_pkg.sv
    ├── fifo_reference_model.sv
    ├── fifo_scoreboard.sv
    ├── fifo_tb_top.sv
    ├── fifo_test.sv
    └── fifo_transaction.sv
```

## Results

Regression over 5 seeds: all passed, 0 errors, 100% functional coverage.

With seed `7777` (300 transactions) coverage was 96.88%, so closure at this transaction count depends on the seed.

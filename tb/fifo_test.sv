class fifo_env #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DEPTH      = 16
);
    virtual fifo_if #(DATA_WIDTH) vif;

    fifo_generator #(DATA_WIDTH)         gen;
    fifo_driver #(DATA_WIDTH)            drv;
    fifo_monitor #(DATA_WIDTH)           mon;
    fifo_scoreboard #(DATA_WIDTH, DEPTH) scb;
    fifo_coverage #(DATA_WIDTH, DEPTH)   cov;

    mailbox #(fifo_transaction #(DATA_WIDTH)) gen2drv_mbx;
    mailbox #(fifo_transaction #(DATA_WIDTH)) mon2scb_mbx;
    mailbox #(fifo_transaction #(DATA_WIDTH)) mon2cov_mbx;

    function new(virtual fifo_if #(DATA_WIDTH) vif);
        this.vif        = vif;
        gen2drv_mbx     = new();
        mon2scb_mbx     = new();
        mon2cov_mbx     = new();

        gen = new(gen2drv_mbx);
        drv = new(vif, gen2drv_mbx);
        mon = new(vif, mon2scb_mbx, mon2cov_mbx);
        scb = new(mon2scb_mbx);
        cov = new(mon2cov_mbx);
    endfunction

    task start_agents();
        fork
            drv.run();
            mon.run();
            scb.run();
            cov.run();
        join_none
    endtask

    task drain();
        wait (drv.driver_count == gen.transaction_count);
        repeat (10) @(vif.monitor_cb);
        wait (mon2scb_mbx.num() == 0);
        repeat (5) @(vif.monitor_cb);
    endtask

    function void report();
        scb.report();
        cov.report();
    endfunction

endclass


class fifo_test #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DEPTH      = 16
);
    fifo_env #(DATA_WIDTH, DEPTH) env;
    virtual fifo_if #(DATA_WIDTH) vif;
    int unsigned num_rand_trans;

    function new(virtual fifo_if #(DATA_WIDTH) vif, int unsigned num_trans = 300);
        this.vif            = vif;
        this.num_rand_trans = num_trans;
        env                 = new(vif);
    endfunction

    // Scenario 1: Directed Sanity
    task test_directed_sanity();
        $display("[SCENARIO 1] Directed Sanity Test");
        env.gen.send_write('0);
        env.gen.send_write('1);
        env.gen.send_write(8'h55);
        env.gen.send_write(8'hAA);
        repeat (4) begin
            env.gen.send_read();
        end
        env.drain();
    endtask

    // Scenario 2: Corner & Stress
    task test_corner_stress();
        $display("[SCENARIO 2] Corner & Stress Test");

        // Overflow: write beyond DEPTH
        env.gen.send_burst_write(DEPTH + 8);
        env.drain();

        // Underflow: read beyond empty
        env.gen.send_burst_read(DEPTH + 8);
        env.drain();

        // Pointer wrap-around
        repeat (3) begin
            env.gen.send_burst_write(DEPTH);
            env.gen.send_burst_read(DEPTH);
        end
        env.drain();
    endtask

    // Scenario 3: Constrained-Random
    task test_random_traffic();
        $display("[SCENARIO 3] Constrained-Random Test (%0d trans)", num_rand_trans);
        env.gen.send_random(num_rand_trans);
        env.drain();
    endtask

    // Watchdog timeout (10,000 cycles)
    task watchdog_timeout(int unsigned max_cycles = 10000);
        repeat (max_cycles) begin
            @(vif.monitor_cb);
        end
        $fatal(1, "[WATCHDOG] Simulation timeout exceeded %0d cycles!", max_cycles);
    endtask

    task run();
        $display("[TEST] Starting FIFO Test Suite");

        env.start_agents();

        fork
            begin
                test_directed_sanity();
                test_corner_stress();
                test_random_traffic();
            end
            begin
                watchdog_timeout(10000);
            end
        join_any
        disable fork;

        env.report();
        $display("[TEST] Completed Successfully");
    endtask

endclass

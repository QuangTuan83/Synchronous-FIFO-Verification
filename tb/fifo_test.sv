
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

    int unsigned num_test_trans;

   
    function new(virtual fifo_if #(DATA_WIDTH) vif, int unsigned num_trans = 300);
        this.vif            = vif;
        this.num_test_trans = num_trans;

        gen2drv_mbx = new();
        mon2scb_mbx = new();
        mon2cov_mbx = new();

        gen = new(gen2drv_mbx, num_test_trans);
        drv = new(vif, gen2drv_mbx);
        mon = new(vif, mon2scb_mbx, mon2cov_mbx);
        scb = new(mon2scb_mbx);
        cov = new(mon2cov_mbx);
    endfunction

   
    task run();
   
        fork
            drv.run();
            mon.run();
            scb.run();
            cov.run();
        join_none

       
        fork
            gen.run();
        join_none

    
        @(gen.gen_done);
        wait(drv.driver_count == gen.transaction_count);
        repeat (5) @(vif.monitor_cb);
        wait(mon2scb_mbx.num() == 0);

       
        scb.report();
        cov.report();
    endtask

endclass



class fifo_test #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DEPTH      = 16
);
    
    fifo_env #(DATA_WIDTH, DEPTH) env;

    
    function new(virtual fifo_if #(DATA_WIDTH) vif, int unsigned num_trans = 300);
        env = new(vif, num_trans);
    endfunction

    
    task run();
        $display("[TEST] Starting test with %0d transactions...", env.num_test_trans);
        env.run();
        $display("[TEST] Test execution completed!");
    endtask

endclass

class fifo_monitor #(
    parameter int unsigned DATA_WIDTH = 8
);
    virtual fifo_if #(DATA_WIDTH) vif;
    mailbox #(fifo_transaction #(DATA_WIDTH)) mon2scb_mbx;
    mailbox #(fifo_transaction #(DATA_WIDTH)) mon2cov_mbx;
    int unsigned monitor_count;

    function new(
        virtual fifo_if #(DATA_WIDTH)             vif,
        mailbox #(fifo_transaction #(DATA_WIDTH)) scb_mbx,
        mailbox #(fifo_transaction #(DATA_WIDTH)) cov_mbx
    );
        this.vif      = vif;
        mon2scb_mbx   = scb_mbx;
        mon2cov_mbx   = cov_mbx;
        monitor_count = 0;
    endfunction

    task run();
        fifo_transaction #(DATA_WIDTH) tr;

        forever begin
            @(vif.monitor_cb);

            tr = new();
            tr.rst_n   = vif.monitor_cb.rst_n;
            tr.wr_en   = vif.monitor_cb.wr_en;
            tr.rd_en   = vif.monitor_cb.rd_en;
            tr.wr_data = vif.monitor_cb.wr_data;

            tr.rd_data  = vif.monitor_cb.rd_data;
            tr.is_full  = vif.monitor_cb.full;
            tr.is_empty = vif.monitor_cb.empty_o;

            mon2scb_mbx.put(tr.clone());
            mon2cov_mbx.put(tr.clone());
            monitor_count++;
        end
    endtask

endclass
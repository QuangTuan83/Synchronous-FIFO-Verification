class fifo_driver #(parameter int unsigned DATA_WIDTH = 8);
    virtual fifo_if #(DATA_WIDTH) vif;
    mailbox #(fifo_transaction #(DATA_WIDTH)) gen2drv_mbx;
    int unsigned driver_count;

    function new (virtual fifo_if #(DATA_WIDTH) vif, mailbox #(fifo_transaction #(DATA_WIDTH)) mbx);
        this.vif = vif;
        this.gen2drv_mbx = mbx;
        this.driver_count = 0;
    endfunction 

    task reset_dut(int unsigned num_cycles = 3);
        @(vif.driver_cb);
        vif.driver_cb.rst_n   <= 1'b0;
        vif.driver_cb.wr_en   <= 1'b0;
        vif.driver_cb.rd_en   <= 1'b0;
        vif.driver_cb.wr_data <= '0;
        repeat (num_cycles) @(vif.driver_cb);
        vif.driver_cb.rst_n   <= 1'b1;
        @(vif.driver_cb);
    endtask

    task run();
        fifo_transaction #(DATA_WIDTH) tr;
        reset_dut(3);

        forever begin
            gen2drv_mbx.get(tr);

            @(vif.driver_cb);
            vif.driver_cb.wr_en   <= tr.wr_en;
            vif.driver_cb.rd_en   <= tr.rd_en;
            vif.driver_cb.wr_data <= tr.wr_data;
            driver_count++;

            if (gen2drv_mbx.num() == 0) begin
                @(vif.driver_cb);
                vif.driver_cb.wr_en   <= 1'b0;
                vif.driver_cb.rd_en   <= 1'b0;
                vif.driver_cb.wr_data <= '0;
            end
        end
    endtask
endclass

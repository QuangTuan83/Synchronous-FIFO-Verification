class fifo_generator #(parameter int unsigned DATA_WIDTH = 8);

    mailbox #(fifo_transaction #(DATA_WIDTH)) gen2drv_mbx;
    int unsigned transaction_count;
    event gen_done;

    function new(mailbox #(fifo_transaction #(DATA_WIDTH)) mbx, int unsigned count = 0);
        this.gen2drv_mbx       = mbx;
        this.transaction_count = count;
    endfunction

    task send_write(logic [DATA_WIDTH-1:0] data);
        fifo_transaction #(DATA_WIDTH) tr;
        tr = new();
        tr.wr_en   = 1'b1;
        tr.rd_en   = 1'b0;
        tr.wr_data = data;
        transaction_count++;
        gen2drv_mbx.put(tr.clone());
    endtask

    task send_read();
        fifo_transaction #(DATA_WIDTH) tr;
        tr = new();
        tr.wr_en   = 1'b0;
        tr.rd_en   = 1'b1;
        transaction_count++;
        gen2drv_mbx.put(tr.clone());
    endtask

    task send_burst_write(int unsigned count);
        fifo_transaction #(DATA_WIDTH) tr;
        repeat (count) begin
            tr = new();
            tr.wr_en   = 1'b1;
            tr.rd_en   = 1'b0;
            tr.wr_data = $urandom;
            transaction_count++;
            gen2drv_mbx.put(tr.clone());
        end
    endtask

    task send_burst_read(int unsigned count);
        fifo_transaction #(DATA_WIDTH) tr;
        repeat (count) begin
            tr = new();
            tr.wr_en   = 1'b0;
            tr.rd_en   = 1'b1;
            transaction_count++;
            gen2drv_mbx.put(tr.clone());
        end
    endtask

    task send_random(int unsigned count);
        fifo_transaction #(DATA_WIDTH) tr;
        repeat (count) begin
            tr = new();
            if (!tr.randomize()) begin
                $fatal(1, "generator[%0t]: Randomization failed!", $time);
            end
            transaction_count++;
            gen2drv_mbx.put(tr.clone());
        end
    endtask

    task run();
        send_random(transaction_count);
        -> gen_done;
    endtask

endclass
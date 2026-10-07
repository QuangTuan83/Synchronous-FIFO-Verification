class fifo_generator #( parameter int unsigned DATA_WIDTH = 8);
    mailbox #(fifo_transaction #(DATA_WIDTH)) gen2drv_mbx;
    int unsigned transaction_count;
    event gen_done;

    function new (mailbox #(fifo_transaction #(DATA_WIDTH)) mbx, int unsigned count);
        gen2drv_mbx = mbx;
        transaction_count = count;
    endfunction
    
    task run();
        fifo_transaction #(DATA_WIDTH) tr;
        $display("generator[%0t]: Generating %0d transactions", $time, transaction_count);
        repeat (transaction_count) begin
            tr = new();
            if(!tr.randomize()) begin
                $fatal(1, "generator[%0t]: Randomization failed", $time);
            end
            gen2drv_mbx.put(tr.clone());
        end
        $display("generator[%0t]: Finished generating %0d transactions", $time, transaction_count);
        -> gen_done;
    endtask
endclass
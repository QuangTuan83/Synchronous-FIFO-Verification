

class fifo_scoreboard #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DEPTH      = 16
);
  
    mailbox #(fifo_transaction #(DATA_WIDTH)) mon2scb_mbx;
    fifo_reference_model #(DATA_WIDTH, DEPTH) ref_model;

    int unsigned comparison_count;
    int unsigned errors_count;

    bit [DATA_WIDTH-1:0] expected_rd_data;
    bit                  initialized;

   
    function new(mailbox #(fifo_transaction #(DATA_WIDTH)) mbx);
        this.mon2scb_mbx      = mbx;
        this.ref_model        = new();
        this.comparison_count = 0;
        this.errors_count     = 0;
        this.expected_rd_data = '0;
        this.initialized      = 0;
    endfunction

 
    task run();
        fifo_transaction #(DATA_WIDTH) tr;
        bit exp_full, exp_empty;
        bit wr_acpt, rd_acpt;

        forever begin
            mon2scb_mbx.get(tr);

          
            if (!tr.rst_n) begin
                ref_model.reset();
                expected_rd_data = '0;
                initialized      = 1;
                continue;
            end

           
            if (!initialized) begin
                continue;
            end

           
            if (tr.rd_data !== expected_rd_data) begin
                $error("[SCB @ %0t] ERROR: rd_data mismatch! Expected: 0x%0h, Actual: 0x%0h",
                       $time, expected_rd_data, tr.rd_data);
                errors_count++;
            end

            
            exp_full  = ref_model.is_full();
            exp_empty = ref_model.is_empty();

            if (tr.is_full !== exp_full) begin
                $error("[SCB @ %0t] ERROR: full flag mismatch! Expected: %0b, Actual: %0b",
                       $time, exp_full, tr.is_full);
                errors_count++;
            end

            if (tr.is_empty !== exp_empty) begin
                $error("[SCB @ %0t] ERROR: empty flag mismatch! Expected: %0b, Actual: %0b",
                       $time, exp_empty, tr.is_empty);
                errors_count++;
            end

            comparison_count++;

           
            wr_acpt = tr.wr_en && !exp_full;
            rd_acpt = tr.rd_en && !exp_empty;

            
            if (rd_acpt) begin
                expected_rd_data = ref_model.read();
            end
            if (wr_acpt) begin
                ref_model.write(tr.wr_data);
            end
        end
    endtask

    
    function void report();
        $display("--------------------------------------------------");
        $display("[SCB] Verification Summary:");
        $display("[SCB]   Total comparisons : %0d", comparison_count);
        $display("[SCB]   Total errors      : %0d", errors_count);
        if (errors_count == 0 && comparison_count > 0) begin
            $display("[SCB]   Status            : PASSED");
        end else begin
            $display("[SCB]   Status            : FAILED");
        end
        $display("--------------------------------------------------");
    endfunction

endclass

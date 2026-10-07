
class fifo_coverage #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DEPTH      = 16
);

    // Member Variables
    mailbox #(fifo_transaction #(DATA_WIDTH)) mon2cov_mbx;
    fifo_transaction #(DATA_WIDTH)            tr;

    // Covergroup 
    covergroup cg_fifo;
        option.per_instance = 1;

        cp_rst: coverpoint tr.rst_n {
            bins active   = {0};
            bins inactive = {1};
        }

        cp_wr: coverpoint tr.wr_en {
            bins no_wr = {0};
            bins do_wr = {1};
        }

        cp_rd: coverpoint tr.rd_en {
            bins no_rd = {0};
            bins do_rd = {1};
        }

        cp_full: coverpoint tr.is_full {
            bins not_full = {0};
            bins is_full  = {1};
        }

        cp_empty: coverpoint tr.is_empty {
            bins not_empty = {0};
            bins is_empty  = {1};
        }

        // Cross coverage on key corner conditions
        cross_wr_full:      cross cp_wr, cp_full;
        cross_rd_empty:     cross cp_rd, cp_empty;  
        cross_simultaneous: cross cp_wr, cp_rd;
    endgroup

    // Constructor
    function new(mailbox #(fifo_transaction #(DATA_WIDTH)) mbx);
        this.mon2cov_mbx = mbx;
        this.cg_fifo     = new();
    endfunction

    task run();
        forever begin
            mon2cov_mbx.get(tr);
            cg_fifo.sample();
        end
    endtask
    function void report();
        $display("--------------------------------------------------");
        $display("[COV] Functional Coverage Report: %0.2f%%", cg_fifo.get_coverage());
        $display("--------------------------------------------------");
        endfunction

endclass

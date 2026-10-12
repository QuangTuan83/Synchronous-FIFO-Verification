class fifo_coverage #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DEPTH      = 16
);

    mailbox #(fifo_transaction #(DATA_WIDTH)) mon2cov_mbx;
    fifo_transaction #(DATA_WIDTH)            tr;

    covergroup cg_fifo;
    
        option.per_instance = 1;

        // Reset
        cp_rst: coverpoint tr.rst_n {
            bins active   = {0};
            bins inactive = {1};
        }

        // Write stimulus
        cp_wr: coverpoint tr.wr_en {
            bins no_wr = {0};
            bins do_wr = {1};
            bins b2b   = (1 [* 2]);
        }

        // Read stimulus
        cp_rd: coverpoint tr.rd_en {
            bins no_rd = {0};
            bins do_rd = {1};
            bins b2b   = (1 [* 2]);
        }

        // Full flag state
        cp_full_flag: coverpoint tr.is_full {
            bins not_full = {0};
            bins is_full  = {1};
        }

        // Full flag toggle
        cp_full_trans: coverpoint tr.is_full {
            bins full_assert   = (0 => 1);
            bins full_deassert = (1 => 0);
        }

        // Empty flag state
        cp_empty_flag: coverpoint tr.is_empty {
            bins not_empty = {0};
            bins is_empty  = {1};
        }

        // Empty flag toggle
        cp_empty_trans: coverpoint tr.is_empty {
            bins empty_assert   = (0 => 1);
            bins empty_deassert = (1 => 0);
        }

        // Corner data values
        cp_wr_data: coverpoint tr.wr_data iff (tr.rst_n && tr.wr_en && !tr.is_full) {
            bins zero     = {'0};
            bins all_ones = {'1};
            bins alt_55   = {8'h55};
            bins alt_aa   = {8'hAA};
            bins others   = default;
        }

        // Cross: Simultaneous R/W & bus modes
        cross_rw: cross cp_wr, cp_rd;

        // Cross: Write vs Full boundary
        cross_wr_full: cross cp_wr, cp_full_flag;

        // Cross: Read vs Empty boundary
        cross_rd_empty: cross cp_rd, cp_empty_flag;

    endgroup

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

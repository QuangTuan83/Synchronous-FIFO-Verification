class fifo_transaction #( parameter int unsigned DATA_WIDTH = 8 );
    
    // Transaction fields
    rand bit [DATA_WIDTH-1:0] wr_data;
    rand bit                  wr_en;
    rand bit                  rd_en;
    
    bit                       rst_n;
    logic [DATA_WIDTH-1:0]    rd_data;
    logic                     is_full;
    logic                     is_empty;

    constraint c_dist {
        wr_en dist { 1'b1 := 60, 1'b0 := 40 };
        rd_en dist { 1'b1 := 50, 1'b0 := 50 };
    }

    function fifo_transaction #(DATA_WIDTH) clone();
        fifo_transaction #(DATA_WIDTH) tr;

        tr = new();

        tr.wr_en   = this.wr_en;
        tr.rd_en   = this.rd_en;
        tr.wr_data = this.wr_data;
        tr.rst_n   = this.rst_n;

        tr.rd_data  = this.rd_data;
        tr.is_full  = this.is_full;
        tr.is_empty = this.is_empty;

        return tr;
    endfunction

    function void display(string tag = "");
        if (tag != "")
            $display("[%s @ %0t] rst_n: %b, wr_en: %b, rd_en: %b, wr_data: 0x%0h, rd_data: 0x%0h, is_full: %b, is_empty: %b",
                     tag, $time, rst_n, wr_en, rd_en, wr_data, rd_data, is_full, is_empty);
        else
            $display("[%0t] rst_n: %b, wr_en: %b, rd_en: %b, wr_data: 0x%0h, rd_data: 0x%0h, is_full: %b, is_empty: %b",
                     $time, rst_n, wr_en, rd_en, wr_data, rd_data, is_full, is_empty);
    endfunction

endclass
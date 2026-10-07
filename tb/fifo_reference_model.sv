class fifo_reference_model #(parameter int unsigned DATA_WIDTH = 8, parameter int unsigned DEPTH = 16);
    bit [DATA_WIDTH-1:0] ref_queue[$];

    function bit is_full();
        return (ref_queue.size() == DEPTH);
    endfunction

    function bit is_empty();
        return (ref_queue.size() == 0);
    endfunction

    function int unsigned size();
        return ref_queue.size();
    endfunction

    function void write(bit [DATA_WIDTH-1:0] data);
        if (!is_full()) begin
            ref_queue.push_back(data);
        end
    endfunction

    function bit [DATA_WIDTH-1:0] read();
        if (!is_empty()) begin
            return ref_queue.pop_front();
        end
        return '0;
    endfunction

    function void reset();
        ref_queue.delete();
    endfunction
endclass

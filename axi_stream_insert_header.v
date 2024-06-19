module axi_stream_insert_header #(
    parameter                               DATA_WD = 32,
    parameter                               DATA_BYTE_WD    = DATA_WD / 8,
    parameter                               BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
) (
    input                                   clk ,
    input                                   rst_n,
    // AXI Stream input original data
    input                                   valid_in,
    input       [DATA_WD-1 : 0]             data_in,
    input       [DATA_BYTE_WD-1 : 0]        keep_in,
    input                                   last_in,
    output                                  ready_in,
    // AXI Stream output with header inserted
    output                                  valid_out,
    output      [DATA_WD-1 : 0]             data_out,
    output      [DATA_BYTE_WD-1 : 0]        keep_out,
    output                                  last_out,
    input                                   ready_out,
    // The header to be inserted to AXI Stream input
    input                                   valid_insert,
    input       [DATA_WD-1 : 0]             data_insert,
    input       [DATA_BYTE_WD-1 : 0]        keep_insert,
    input       [BYTE_CNT_WD-1 : 0]         byte_insert_cnt,
    output                                  ready_insert    
);
    // header data
    reg        [DATA_WD-1 : 0]              header_data_r;
    reg                                     header_valid_r;
    reg        [DATA_BYTE_WD-1 : 0]         header_keep_r;
    reg        [BYTE_CNT_WD-1 : 0]          header_byte_cnt_r;
    reg        [BYTE_CNT_WD-1 : 0]          header_byte_cnt_r2;
    // data
    reg                                     data_valid_r;
    reg                                     data_last_r;
    // extended for concat
    reg        [DATA_WD*2-1:0]              data_extended;         
    wire       [DATA_WD*2-1:0]              data_aligned;                          
    reg        [DATA_BYTE_WD*2-1:0]         keep_extended;
    wire        [DATA_BYTE_WD*2-1:0]         keep_aligned;
    // handshake
    wire                                    header_handshake;
    wire                                    data_handshake;
    reg                                     data_handshake_r;

    wire                                    not_finish;
    wire                                    header_pulse_r;
    // --------------------------------------------------------
    //header ready
    assign      ready_insert     = !header_valid_r || valid_in && last_in;//not valid || last in
    assign      header_handshake = valid_insert && ready_insert;
    //  header valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            header_valid_r <= 0;
        else begin
            if (ready_insert)
                header_valid_r <= valid_insert;
        end
    end
    // header data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            header_byte_cnt_r <= 0;
            header_byte_cnt_r2 <= 0;
            header_data_r <= 0;
            header_keep_r <= 0;
        end
        else begin
            if (header_handshake) begin
                header_byte_cnt_r <= byte_insert_cnt;
                header_byte_cnt_r2 <= header_byte_cnt_r;
                header_data_r <= data_insert;
                header_keep_r <= keep_insert;
            end
        end
    end

    // data ready
    assign      ready_in = header_valid_r  && (!data_valid_r || ready_out);// TODO
    assign      data_handshake = valid_in && ready_in;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) data_handshake_r <= 0;
        else data_handshake_r <= data_handshake;
    end
    // data valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) data_valid_r <= 0;
        else begin
            if (ready_in)
                data_valid_r <= valid_in && header_valid_r;
        end
    end
    // data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_last_r <= 0;
        end
        else begin
            if (data_handshake)
                data_last_r <= last_in;
            else
                data_last_r <= 0;
        end
    end
    assign not_finish       = |keep_aligned[DATA_BYTE_WD-1:0];
    assign header_pulse_r   = data_handshake & !data_handshake_r & !not_finish;
    // concat header and data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_extended <= 0;
            keep_extended <= 0;
        end
        else begin
            if (data_handshake || (data_last_r && (|keep_aligned[DATA_BYTE_WD*2-1:0]))) begin
                if (header_pulse_r) begin
                    data_extended[DATA_WD*2-1:0] <= {header_data_r, data_in};
                    keep_extended[DATA_BYTE_WD*2-1:0] <= {header_keep_r, keep_in};
                end else begin
                    data_extended[DATA_WD*2-1:0] <= {data_extended[DATA_WD-1:0], header_valid_r ? data_in : {DATA_WD{1'b0}}};
                    keep_extended[DATA_BYTE_WD*2-1:0] <= {keep_extended[DATA_BYTE_WD-1:0], header_valid_r ? keep_in : {DATA_BYTE_WD{1'b0}}};
                end
            end
        end
    end
    // empty shift num
    reg     [BYTE_CNT_WD-1:0]      empty_byte_cnt_r;
    wire    [BYTE_CNT_WD+3-1:0]    empty_byte_cnt_bit;
    wire    [BYTE_CNT_WD-1:0]      header_byte_cnt = (not_finish & valid_insert) ? header_byte_cnt_r2 : header_byte_cnt_r; //r2 avoid overwriting
    wire    [BYTE_CNT_WD-1:0] temp = DATA_BYTE_WD - header_byte_cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) empty_byte_cnt_r <= 0;
        else begin
            if (header_pulse_r) begin
                empty_byte_cnt_r <= temp;
            end
        end
    end
    assign empty_byte_cnt_bit = empty_byte_cnt_r << 3;
    // data and keep by shift
    assign data_aligned = data_extended << empty_byte_cnt_bit;
    assign data_out     = data_aligned[DATA_WD*2-1:DATA_WD]; 
    assign keep_aligned = keep_extended[DATA_BYTE_WD*2-1:0] << empty_byte_cnt_r;
    assign keep_out     = keep_aligned[DATA_BYTE_WD*2-1:DATA_BYTE_WD]; 

    assign valid_out    = data_handshake_r || last_out;
    assign last_out     = |keep_aligned[DATA_BYTE_WD*2-1:DATA_BYTE_WD] && !not_finish;

endmodule
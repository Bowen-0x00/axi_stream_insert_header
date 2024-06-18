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
    reg        [DATA_WD-1 : 0]              header_data_r;
    reg                                     header_valid_r;
    reg        [DATA_BYTE_WD-1 : 0]         header_keep_r;
    reg        [BYTE_CNT_WD-1 : 0]          header_byte_cnt_r;

    reg                                     data_last_r;

    //extended for align
    reg        [DATA_WD*2-1:0]              data_extended;         
    wire       [DATA_WD*2-1:0]              data_aligned;                          

    reg        [DATA_BYTE_WD*2-1:0]         keep_extended;
    reg        [DATA_BYTE_WD*2-1:0]         keep_aligned;

    reg                                     data_valid_r;

    wire                                    header_ready;
    reg                                     first_data_r;
    reg                                     data_handshake_r;

    assign      ready_insert = !header_valid_r || valid_in && last_in;//last data

    wire        header_handshake;
    assign      header_handshake = valid_insert && ready_insert;

    assign      ready_in = header_valid_r  && (!data_valid_r || ready_out);// TODO
    wire        data_handshake;
    assign      data_handshake = valid_in && ready_in;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            header_valid_r <= 0;
        else begin
            if (ready_insert)
                header_valid_r <= valid_insert;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            header_byte_cnt_r <= 0;
            header_data_r <= 0;
            header_keep_r <= 0;
        end
        else begin
            if (header_handshake) begin
                header_byte_cnt_r <= byte_insert_cnt;
                header_data_r <= data_insert;
                header_keep_r <= keep_insert;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) data_handshake_r <= 0;
        else data_handshake_r <= data_handshake;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) data_valid_r <= 0;
        else begin
            if (ready_out)
                data_valid_r <= valid_in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_last_r <= 0;
        else begin
            if (data_handshake)
                data_last_r <= last_in;
            else
                data_last_r <= 0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            first_data_r <= 0;
        else begin
            if (!keep_extended[DATA_BYTE_WD*2-1:DATA_BYTE_WD] && keep_extended[DATA_BYTE_WD-1:0])
                first_data_r <= 1;
            else
                first_data_r <= 0;
        end
    end
    reg header_pulse_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) header_pulse_r <= 0;
        else begin
            if (valid_insert && !header_pulse_r)
                header_pulse_r <= 1;
            else
                header_pulse_r <= 0;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_extended <= 0;
            keep_extended <= 0;
        end
        else begin
            // if (header_handshake) begin
            //     data_extended[DATA_WD-1:0] <= data_insert;
            //     keep_extended[DATA_BYTE_WD-1:0] <= keep_insert;
            // end
            if (data_handshake) begin
                if (header_pulse_r) begin
                data_extended[DATA_WD*2-1:0] <= {header_data_r, data_in};
                keep_extended[DATA_BYTE_WD*2-1:0] <= {header_keep_r, keep_in};
                end else begin
                data_extended[DATA_WD*2-1:0] <= {data_extended[DATA_WD-1:0], data_in};
                keep_extended[DATA_BYTE_WD*2-1:0] <= {keep_extended[DATA_BYTE_WD-1:0], keep_in};
                end
            end

        end
    end

    wire [BYTE_CNT_WD-1:0] empty_byte_cnt;
    wire [BYTE_CNT_WD+3-1:0] empty_byte_cnt_bit;

    assign empty_byte_cnt = DATA_BYTE_WD - header_byte_cnt_r; // empty bits before header
    assign empty_byte_cnt_bit = empty_byte_cnt << 3;

    assign data_aligned = data_extended << empty_byte_cnt_bit;
    assign data_out = data_aligned[DATA_WD*2-1:DATA_WD]; 
    assign keep_aligned = keep_extended[DATA_BYTE_WD*2-1:0] << empty_byte_cnt;
    assign keep_out = data_last_r ? keep_aligned[DATA_BYTE_WD-1:0]: keep_aligned[DATA_BYTE_WD*2-1:DATA_BYTE_WD]; 

    assign valid_out = data_handshake_r;// 再或上最后多的keep不为0
    assign last_out = data_valid_r ? data_last_r : 0;

endmodule
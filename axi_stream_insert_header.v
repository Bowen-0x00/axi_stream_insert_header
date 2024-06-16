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
    //header
    reg         [DATA_WD-1:0]               header_r1;
    reg         [DATA_BYTE_WD-1:0]          header_keep_r1;
    reg         [BYTE_CNT_WD-1:0]           header_byte_cnt_r1;
    reg         [BYTE_CNT_WD-1:0]           header_byte_cnt_r2;
    reg         [BYTE_CNT_WD-1:0]           header_byte_cnt_r3;
    reg                                     header_valid_r1;
    //data
    reg                                     data_valid_r1;
    reg         [DATA_WD-1:0]               data_r1;
    reg         [DATA_BYTE_WD-1: 0]         data_keep_r1;
    reg                                     data_last_r1;
    //r2
    reg                                     data_valid_r2;
    reg                                     data_last_r2;

    //extended for align
    reg        [DATA_WD*2-1:0]              data_extended;         
    reg        [DATA_WD*2-1:0]              data_aligned;                          


    reg        [DATA_BYTE_WD*2-1:0]         keep_extended;
    reg        [DATA_BYTE_WD*2-1:0]         keep_aligned;

    //handshake
    wire                                    header_insert_handshake;
    wire                                    data_handshake;
    wire                                    out_handshake;
    wire                                    r2_handshake;

    assign header_insert_handshake = valid_insert && ready_insert;
    assign data_handshake          = valid_in && ready_in && header_valid_r1;    
    assign out_handshake           = valid_out && ready_out;
    assign r2_handshake            = valid_r1 && ready_r1;//


    // stall
    reg                                     valid_r1;
    wire                                    ready_r1;
    reg                                     valid_r2;
    wire                                    ready_r2;

    assign ready_in = (!valid_r1 || ready_r1) && header_valid_r1; // r1 empty || r2 ready

//r1
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n)
            valid_r1 <= 0;
        else if (ready_in & header_valid_r1) // header and data valid
            valid_r1 <= valid_in;
    end

    // header valid
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            header_valid_r1 <= 0;
        end else begin
            if (header_insert_handshake)
                header_valid_r1 <= '1;
            else if (out_handshake && last_in)
                header_valid_r1 <= '0;
        end
    end
    // store header when handshake
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            header_r1        <= 0;
            header_keep_r1   <= 0;
            header_byte_cnt_r1 <= 0;
        end else begin
            if (header_insert_handshake) begin
                header_r1        <= data_insert;
                header_keep_r1   <= keep_insert;
                header_byte_cnt_r1 <= byte_insert_cnt;
            end
        end
    end


    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            data_valid_r1 <= 0;
            data_r1       <= 0;
            data_keep_r1  <= 0;
            data_last_r1  <= 0;
            data_last_r1 <= 0;
        end else begin
            if (data_handshake & !data_last_r1) begin
                data_valid_r1 <= valid_in;
                data_r1       <= data_in;
                data_keep_r1  <= keep_in;
                data_last_r1  <= last_in;
            end else if (data_last_r1) begin
                data_valid_r1 <= 0;
                data_r1       <= 0;
                data_keep_r1  <= 0;
                data_last_r1  <= 0;
            end
        end
    end

    wire [BYTE_CNT_WD-1:0] empty_byte_cnt;
    wire [BYTE_CNT_WD+3-1:0] empty_byte_cnt_bit;

    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) header_byte_cnt_r2 <= 0;
        else if (r2_handshake) 
            header_byte_cnt_r2 <= header_byte_cnt_r1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) header_byte_cnt_r3 <= 0;
        else if (r2_handshake) 
            header_byte_cnt_r3 <= header_byte_cnt_r2;
    end


    assign empty_byte_cnt = DATA_BYTE_WD - header_byte_cnt_r3; // empty bits before header
    assign empty_byte_cnt_bit = empty_byte_cnt << 3;

    wire first_data;
    assign first_data = data_valid_r1 & !data_valid_r2;


//r2
    assign ready_r1 = !valid_r2 || ready_out;

    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n)
            valid_r2 <= 0;
        else if (ready_r1)
            valid_r2 <= valid_r1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_extended <= 0;
            keep_extended <= 0;
        end
        else begin
            if (ready_r1) begin
                if (first_data) begin
                    data_extended[DATA_WD*2-1:0]      <= {header_r1, data_r1};
                    keep_extended[DATA_BYTE_WD*2-1:0] <= {header_keep_r1, data_keep_r1};
                end
                else if (|data_extended) begin
                    data_extended[DATA_WD*2-1:0]      <= {data_extended[DATA_WD-1:0], data_r1[DATA_WD-1:0]};
                    keep_extended[DATA_BYTE_WD*2-1:0] <= {keep_extended[DATA_BYTE_WD-1:0], data_keep_r1[DATA_BYTE_WD-1:0]};
                end else begin
                    data_extended[DATA_WD*2-1:0] <= 0;
                    keep_extended[DATA_BYTE_WD*2-1:0] <= 0;
                end
            end
        end
    end


    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n)
            data_valid_r2 <= 0;
        else
            data_valid_r2 <= data_valid_r1;
    end


    assign data_aligned = data_extended[DATA_WD*2-1:0] << empty_byte_cnt_bit;
    assign data_out = data_aligned[DATA_WD*2-1:DATA_WD]; 
    assign keep_aligned = keep_extended[DATA_BYTE_WD*2-1:0] << empty_byte_cnt;
    assign keep_out = keep_aligned[DATA_BYTE_WD*2-1:DATA_BYTE_WD]; 

    assign valid_out = ready_out & |keep_aligned;

    assign ready_insert = !header_valid_r1 || (ready_out && last_out);

    assign last_out = !(|(keep_extended[DATA_BYTE_WD-1:0] << empty_byte_cnt)) & valid_out;

endmodule
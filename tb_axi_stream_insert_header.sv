`timescale  1ns / 1ps

`ifndef INCLUDE
`include "src/axi_stream_insert_header_1.v"
`endif
module tb_axi_stream_insert_header;

// axi_stream_insert_header Parameters
parameter PERIOD        = 10                 ;
parameter DATA_WD       = 32                 ;
parameter DATA_BYTE_WD  = DATA_WD / 8        ;
parameter BYTE_CNT_WD   = $clog2(DATA_BYTE_WD);
parameter LAST_CNT      = 2;

// axi_stream_insert_header Inputs
reg   clk                                  = 0 ;
reg   rst_n                                = 0 ;
reg   valid_in                             = 0 ;
reg   [DATA_WD-1 : 0]  data_in             = 0 ;
reg   [DATA_BYTE_WD-1 : 0]  keep_in        = 0 ;
reg   last_in                              = 0 ;
reg   ready_out                            = 0 ;
reg   valid_insert                         = 0 ;
reg   [DATA_WD-1 : 0]  data_insert         = 0 ;
reg   [DATA_BYTE_WD-1 : 0]  keep_insert    = 0 ;
reg   [BYTE_CNT_WD-1 : 0]  byte_insert_cnt = 0 ;

// axi_stream_insert_header Outputs
wire  ready_in                             ;
wire  valid_out                            ;
wire  [DATA_WD-1 : 0]  data_out            ;
wire  [DATA_BYTE_WD-1 : 0]  keep_out       ;
wire  last_out                             ;
wire  ready_insert                         ;


initial begin
    $dumpfile("tb_axi_stream_insert_header.vcd");
    $dumpvars(0, tb_axi_stream_insert_header);
end


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    clk <= 0;
    #(PERIOD*2) rst_n  =  1;
end

axi_stream_insert_header #(
    .DATA_WD      ( DATA_WD      ),
    .DATA_BYTE_WD ( DATA_BYTE_WD ),
    .BYTE_CNT_WD  ( BYTE_CNT_WD  ))
 u_axi_stream_insert_header (
    .clk                     ( clk                                   ),
    .rst_n                   ( rst_n                                 ),
    .valid_in                ( valid_in                              ),
    .data_in                 ( data_in          [DATA_WD-1 : 0]      ),
    .keep_in                 ( keep_in          [DATA_BYTE_WD-1 : 0] ),
    .last_in                 ( last_in_r                               ),
    .ready_out               ( ready_out                             ),
    .valid_insert            ( valid_insert                          ),
    .data_insert             ( data_insert      [DATA_WD-1 : 0]      ),
    .keep_insert             ( keep_insert      [DATA_BYTE_WD-1 : 0] ),
    .byte_insert_cnt         ( byte_insert_cnt  [BYTE_CNT_WD-1 : 0]  ),

    .ready_in                ( ready_in                              ),
    .valid_out               ( valid_out                             ),
    .data_out                ( data_out         [DATA_WD-1 : 0]      ),
    .keep_out                ( keep_out         [DATA_BYTE_WD-1 : 0] ),
    .last_out                ( last_out                              ),
    .ready_insert            ( ready_insert                          )
);

reg last_in_r = 0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        last_in <= 0;
        keep_in <= 0;
        last_in_r <= 0;
    end
    else begin
        if (valid_in) begin
            last_in_r <= last_in;
            if (last_in_r) begin
                last_in <= 0;
                last_in_r <= 0;
                keep_in <= 4'b1111;
            end
            else if (last_in) begin
                keep_in <= 4'b1100;
            end
            else keep_in <= 4'b1111;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_in <= 32'h01020304;
    end
    else begin
        if (valid_in & ready_in) begin
            data_in <= data_in + 32'h04040404;
        end
    end
end


initial
begin
    valid_in <= 1;
    last_in <= 0;

    ready_out <= '1;
    valid_insert <= '0;

    data_insert <= 32'hAA55AA55;
    keep_insert <= 4'b0111;
    byte_insert_cnt <= 'd3;
    #(PERIOD*5)
    valid_insert <= 1;
    #(PERIOD*1)
    valid_insert <= 0;
    #(PERIOD*2)
    ready_out <= '0;
    #(PERIOD*4)
    ready_out <= '1;
    #(PERIOD*5)
    last_in <= 1;

    #(PERIOD*2)
    valid_insert <= 1;
    data_insert <= 32'hAA55AA66;
    keep_insert <= 4'b0001;
    byte_insert_cnt <= 'd1;
    valid_in <= 1;
    #(PERIOD*1)
    valid_insert <= 0;
    #(PERIOD*5)
    last_in <= 1;

    #(PERIOD*1)
    
    #(PERIOD*1)
    valid_insert <= 1;
    keep_insert <= 4'b1111;
    byte_insert_cnt <= 'd4;
    data_insert <= 32'hAA55AA77;
    #(PERIOD*1)
    data_insert <= 32'hAA55AA88;
    #(PERIOD*1)
    valid_insert <= 0;
    #(PERIOD*1)
    valid_in <= 0;
    #(PERIOD*4)
    valid_in <= 1;
    #(PERIOD*1)
    last_in <= 1;
    
    #(PERIOD*10)
    $finish;
end

endmodule
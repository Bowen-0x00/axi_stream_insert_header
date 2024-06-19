`timescale  1ns / 1ps

`ifndef INCLUDE
`include "src/axi_stream_insert_header.v"
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
    .last_in                 ( last_in                               ),
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

reg data_sig;
reg last_sig;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        last_in <= 0;
        keep_in <= 0;
        
    end
    else begin
        if (data_sig) begin
            
            if (last_sig & !last_in) begin
                // keep_in <= 4'b1100;
                last_cnt = $urandom_range(0, DATA_BYTE_WD-1);
		        keep_in = 4'hf << last_cnt;
                last_in <= 1;
            end else 
                keep_in <= 4'b1111;
        end
        if (last_sig & !last_in) begin
            
        end
        else last_in <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_in <= 32'h01020304;
    end
    else begin
        valid_in <= data_sig;
        if (data_sig & ready_in) begin
            data_in <= data_in + 32'h04040404;
        end
    end
end

reg head_sig;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_insert <= 32'hAABBCC00;
        keep_insert <= 0;
        byte_insert_cnt <= 0;
    end
    else begin
        valid_insert <= head_sig;
        // byte_insert_cnt <= 0;
        if (head_sig & ready_insert) begin
            data_insert <= data_insert + 32'h00000011;
            // keep_insert <= 4'b0111;
            // byte_insert_cnt <= 3;
            hdr_cnt = $urandom_range(1, DATA_BYTE_WD-1);
		    keep_insert = 4'hf >> (DATA_BYTE_WD - hdr_cnt);
		    byte_insert_cnt = hdr_cnt;
        end
    end
end

task data_valid; 
    begin
        data_sig <= 1;
    end
endtask
task data_invalid; 
    begin
        data_sig <= 0;
    end
endtask
task last; 
    begin
        last_sig <= 1;
        #(PERIOD*1)
        last_sig <= 0;
    end
endtask
task head; 
    begin
        head_sig <= 1;
        #(PERIOD*1)
        head_sig <= 0;
    end
endtask

task ready; 
    begin
        ready_out <= 1;
    end
endtask

task notready; 
    begin
        ready_out <= 0;
    end
endtask

reg [3:0] rand_val1;
reg [3:0] rand_val2;
reg [3:0] rand_val3;
reg [31:0] seed=1;
reg	[DATA_BYTE_WD-1:0] last_cnt;
reg	[BYTE_CNT_WD-1:0] hdr_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        
    end else begin
        rand_val1 = $random(seed);
        rand_val2 = $random(seed);
        rand_val3 = $random(seed);
        if (rand_val1 < 10) begin
            data_valid;
            if (rand_val1 < 2)
                last;
        end else begin
            data_invalid;
        end

        if (rand_val2 < 10) begin
            head;
        end
        if (rand_val3 < 14) begin
            ready;
        end else begin
            notready;
        end
    end
end
initial
begin
    head_sig <= 0;
    data_sig <= 0;
    last_sig <= 0;
    ready_out <= 1;


    #(PERIOD*100)
    $finish;
end

endmodule
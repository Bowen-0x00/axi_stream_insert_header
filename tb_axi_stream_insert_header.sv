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

task hdr_value;
    
	begin
		valid_insert <= 1'b1;
		data_insert <= $random(seed);
		hdr_cnt <= $urandom_range(0, DATA_BYTE_WD);
		keep_insert <= 4'hf >> (DATA_BYTE_WD - hdr_cnt);
		byte_insert_cnt <= hdr_cnt;
	end
endtask

task send_data;
	begin
		cnt <= 0;
	end
endtask



task test_insert_data;
	begin
		send_data;
		hdr_value;
		@(posedge clk)
		valid_insert <= 1'b0;
	    repeat (LAST_CNT+2)
        @(posedge clk);
	end
endtask

task test_insert_before_data;
	begin
		hdr_value;
		@(posedge clk);
		valid_insert <=1'b0;
		send_data;
		repeat (LAST_CNT+2)
        @(posedge clk);
	end
endtask

task test_insert_after_data;
	begin
		send_data;
		@(posedge clk);
		hdr_value;
        @(posedge clk);
        valid_insert <=1'b0;
        repeat (2)
		@(posedge clk);
        ready_out <= '0;
        repeat (5)
        @(posedge clk);
        ready_out <= '1;
        repeat (LAST_CNT+1)
        @(posedge clk);
	end
endtask


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

reg [2:0] cnt;
reg	[DATA_BYTE_WD-1:0] last_cnt;
reg	[BYTE_CNT_WD-1:0] hdr_cnt;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_in <= 0;
        last_in <= 0;
        keep_in <= 0;
        data_in <= $random(seed);
        last_cnt <= $random(seed);
        hdr_cnt <= $random(seed);
    end
    else begin
        if (cnt < LAST_CNT) begin
            valid_in <= 1;
            last_in <= 0;
            keep_in <= 4'b1111;    
        end else if (cnt == LAST_CNT) begin
            valid_in <= 1;
            last_in <= 1;
            if (valid_in & ready_in) begin
            last_cnt <= $random(seed);
		    keep_in <= 4'hf << last_cnt;
            end
        end
        else begin
            valid_in <= 0;
            last_in <= 0;
            keep_in <= 0;
        end
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 0;
        data_in <= $random(seed);
    end
    else begin
        if (valid_in & ready_in) begin
            cnt <= cnt + 1;
            if (cnt <= LAST_CNT)
                data_in <= $random(seed);
            else
                data_in <= 0;
        end
    end
end

// initial
// begin
//     ready_out <= '1;

//     valid_insert <= '0;

//     data_insert <= 32'h01020304;
//     keep_insert <= 4'b0111;
//     byte_insert_cnt <= 'd3;
//     #(PERIOD*5)
//     valid_insert <= 1;
//     #(PERIOD*1)
//     valid_insert <= 0;
//     #(PERIOD*2)
//     ready_out <= '0;
//     #(PERIOD*4)
//     ready_out <= '1;
//     #(PERIOD*10)
//     $finish;
// end
reg test = 0;
reg [31:0] seed=4;
initial 
begin
	ready_out =1'b1;
    #(PERIOD*3)
	// test_insert_data;
	// @(posedge clk);
	// test_insert_before_data;
    // test = 1;
	// @(posedge clk);
	test_insert_after_data;
    #(PERIOD*20)
    $finish;
end

endmodule
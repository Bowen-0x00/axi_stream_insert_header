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

//-----------------------------------------激励-----------------------------------------------
reg data_sig;
reg last_sig;
reg [31:0] seed=1;
reg	[DATA_BYTE_WD-1:0] last_cnt;
reg	[BYTE_CNT_WD-1:0] hdr_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        last_in <= 0;
        keep_in <= 0;
        last_cnt <= $urandom_range(0, DATA_BYTE_WD-1);
        keep_in <= 4'hf;
    end
    else begin
        if (data_sig) begin
            keep_in <= 4'b1111;
            last_in <= 0;
            if (last_sig & !last_in) begin
                // keep_in <= 4'b1100;
                last_cnt <= $urandom_range(0, DATA_BYTE_WD-1);
		        keep_in <= 4'hf << last_cnt;
                last_in <= 1;
            end
        end
        if (last_sig & !last_in) begin
            
        end
        else begin
            last_in <= 0;
            keep_in <= 4'b1111;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_in <= 32'h01020304;
    end
    else begin
        valid_in <= data_sig;
        if (valid_in & ready_in) begin
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
        hdr_cnt <= $urandom_range(0, DATA_BYTE_WD-1);
		keep_insert <= 4'hf >> (DATA_BYTE_WD - hdr_cnt - 1);
		byte_insert_cnt <= hdr_cnt;
    end
    else begin
        valid_insert <= head_sig;
        // byte_insert_cnt <= 0;
        if (valid_insert & ready_insert) begin
            data_insert <= data_insert + 32'h00000011;
            // keep_insert <= 4'b0111;
            // byte_insert_cnt <= 3;
            hdr_cnt <= $urandom_range(0, DATA_BYTE_WD-1);
		    keep_insert <= 4'hf >> (DATA_BYTE_WD - hdr_cnt - 1);
		    byte_insert_cnt <= hdr_cnt;
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

//--------------------------record------------------------------------------

integer fd_input, fd_output;
reg [31:0] header_r;
reg [31:0] header_keep_r;
reg [3:0] byte_insert_cnt_r;
reg first_head = 1;

task display_by_keep(input integer fd, input logic [DATA_WD-1 : 0]  data, input logic [DATA_BYTE_WD-1 : 0] keep);
begin
    integer i;
    for (i = DATA_BYTE_WD-1; i >= 0; i=i-1) begin
        if (keep[i])
            $fwrite(fd, "%X", data[i*8+:8]);
    end
end
endtask

task display_by_keep2(input logic [DATA_WD-1 : 0]  data, input logic [DATA_BYTE_WD-1 : 0] keep);
begin
    integer i;
    for (i = DATA_BYTE_WD-1; i >= 0; i=i-1) begin
        if (keep[i])
            $fwrite(fd_output, "%X", data[i*8+:8]);
    end
end
endtask

always @(posedge clk) begin
    if (ready_insert && valid_insert) begin
        header_r <= data_insert;
        header_keep_r <= keep_insert;
        byte_insert_cnt_r <= byte_insert_cnt;
    end
end

always @(negedge clk) begin
    if (ready_in && valid_in) begin
        if (first_head) begin
            first_head <= 0;
            // $fwrite("head: %X  keep: %X", header_r, byte_insert_cnt_r);
            display_by_keep(fd_input, header_r, header_keep_r);
        end
        if (last_in) begin
            display_by_keep(fd_input, data_in, keep_in);
            $fwrite(fd_input, "\n");
            first_head <= 1;
        end
        else begin
            $fwrite(fd_input, "%X", data_in);      
        end
    end
end

always @(negedge clk) begin
    if (ready_out && valid_out) begin
        if (last_out) begin
            display_by_keep2(data_out, keep_out);
            $fwrite(fd_output, "\n");
        end
        else 
            $fwrite(fd_output, "%X", data_out);
    end
end
reg [1000:0] line1, line2;
bit files_equal;
int status1, status2;

//--------------------------compare------------------------------------------
task comp_file();
begin
    fd_input = $fopen("./input.txt", "r");
    if (fd_input == 0) begin
        $display("Error opening input.txt");
    end

    fd_output = $fopen("./output.txt", "r");
    if (fd_output == 0) begin
        $display("Error opening output.txt");
    end
    files_equal = 1;

    while (!$feof(fd_input) && !$feof(fd_output)) begin
        status1 = $fgets(line1, fd_input);
        status2 = $fgets(line2, fd_output);

        if (line1 != line2) begin
            files_equal = 0;
            // break;
        end
    end

    if (!$feof(fd_input) || !$feof(fd_output)) begin
        files_equal = 0;
    end

    $fclose(fd_input);
    $fclose(fd_output);
    if (files_equal) begin
        $display("The files are identical.");
    end else begin
        $display("The files are different.");
    end
end
endtask


initial
begin
    fd_input = $fopen("./input.txt", "w+"); 
    fd_output = $fopen("./output.txt", "w+"); 
    head_sig <= 0;
    data_sig <= 0;
    last_sig <= 0;
    ready_out <= 1;


    #(PERIOD*1000)
    $fclose(fd_input);
    $fclose(fd_output);
    comp_file();
    $finish;
end
 
endmodule
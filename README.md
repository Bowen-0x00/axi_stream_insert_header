`testbench\tb_axi_stream_insert_header_random.sv` 为随机tb，data按序增长;
- valid_insert
- keep_insert
- byte_insert_cnt
- valid_in
- keep_in
- last_in

等信号全部随机。

tb中会记录预期输出与实际输出（按照keep_out的data_out），并进行对比，当一致时输出success，否则会输出不一致

build目录下是我运行了1000多时钟周期，90个合并的信号流的结果，实际输出与预期值一致。
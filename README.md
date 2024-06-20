一个周期延迟输出（时钟沿输出header和第一个data的部分，每个时钟周期输出当前data的一部分，剩余在下个周期输出）

manual 为手动构造测试例的仿真结果：
- 无气泡传输
- 中途ready_out拉低，逐级反压（ready_out直接以组合逻辑传递拉低ready_in）
- last_out与last_in同周期以及last_out在last_in下个周期



random为随机测试例仿真结果：
- 无气泡传输（第二个last_out处）
- 中途ready_out拉低，逐级反压


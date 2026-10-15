# PPA-Lite 四次实验实施指南

本文依据[《实验内容.md》](./实验内容.md)整理成可直接执行的开发路线。目标不是重新抄一遍规格，而是回答四个问题：先写什么、模块内部怎么组织、怎样验证、做到什么程度算完成。

## 1. 先理解整个项目

PPA-Lite 的数据和控制路径如下：

```text
APB Master
    |
    v
M1 apb_slave_if ----控制/状态---- M3 packet_proc_core
    |                                  |
    | APB 写口、APB 读口               | 处理读口
    v                                  v
              M2 packet_sram
                 8 x 32 bit
```

- M1 负责 APB 协议、地址译码、CSR、写保护和中断。
- M2 只负责存储，采用 1 个写口和 2 个独立读口，不理解 Packet 格式。
- M3 负责读取 Packet、解析头部、检查格式并计算 payload 摘要。
- `ppa_top` 只连线和分发时钟/复位，不应增加新的状态机或寄存器行为。

四次实验不是四套独立工程，而是逐层扩展同一个工程：

| 实验 | 主要产物 | 后续用途 |
| --- | --- | --- |
| Lab1 | M1、M2、APB TB | Lab3 直接复用 |
| Lab2 | M3、M3 独立 TB | Lab3 直接复用 |
| Lab3 | 顶层与集成 TB | Lab4 回归基础 |
| Lab4 | 回归、覆盖率、testplan | 最终交付 |

## 2. 推荐工程结构

一开始就按最终交付结构建目录，避免 Lab4 再搬文件：

```text
Digital-IC/
├─ rtl/
│  ├─ apb_slave_if.sv
│  ├─ packet_sram.sv
│  ├─ packet_proc_core.sv
│  └─ ppa_top.sv
├─ tb/
│  ├─ common/
│  │  ├─ apb_if.sv
│  │  ├─ apb_tasks.sv
│  │  └─ packet_model.sv
│  ├─ lab1/
│  ├─ lab2/
│  └─ integration/
├─ sim/
│  ├─ filelist.f
│  ├─ tests.list
│  └─ result_summary.txt
├─ cov/
├─ doc/
│  └─ testplan.md
└─ Makefile
```

建议从 Lab1 起就提供统一命令：

```text
make smoke TEST=<test_name> SEED=<seed>
make regress
make cov
```

`smoke` 跑单条最小测试，`regress` 跑测试列表，`cov` 合并覆盖率并生成报告。每条测试必须用退出码和清晰的 `PASS/FAIL` 文本表示结果。

## 3. 开始编码前必须统一的规则

### 3.1 Packet 字节序

规格附录使用：

```systemverilog
32'h08_01_00_09
```

并解释为 `pkt_len=8, pkt_type=1, flags=0, hdr_chk=9`。因此本项目应统一为：

```text
Word0[31:24] = Byte0 = pkt_len
Word0[23:16] = Byte1 = pkt_type
Word0[15:8]  = Byte2 = flags
Word0[7:0]   = Byte3 = hdr_chk
```

后续 Word 同样按高字节到低字节排列。建议把取字节写成公共函数，例如逻辑意义上的 `get_byte(word, index)`，不要在多个模块和 scoreboard 中重复手写位选。

### 3.2 同步 SRAM 与零等待 APB 读

M2 被定义为同步 SRAM，但 APB 又要求 `PREADY=1`。可行的时序是：

1. APB SETUP 拍出现读地址，M1 在 SETUP 阶段拉高 `pkt_mem_re_o`。
2. SETUP 结束的上升沿，M2 对地址采样并更新 `apb_rd_data`。
3. 下一拍进入 ACCESS，M1 将 `apb_rd_data` 放到 `PRDATA`，同时 `PREADY=1`。

这样既保留同步读口，也不需要 APB 等待态。若等到 ACCESS 才发 SRAM 读请求，数据会晚一拍，无法满足当前协议约定。

### 3.3 APB 传输定义

建议统一定义：

```text
apb_setup  = PSEL && !PENABLE
apb_access = PSEL &&  PENABLE
apb_write  = apb_access && PWRITE
apb_read   = apb_access && !PWRITE
```

- 所有 CSR 写副作用只发生在 `apb_write` 的上升沿。
- `PREADY` 固定为 1。
- `PRDATA`、`PSLVERR` 在 ACCESS 阶段有效。
- SETUP 到 ACCESS 期间，Master 必须保持 `PADDR/PWRITE/PWDATA` 稳定。

### 3.4 `start` 的接受条件

一次启动只有在以下条件同时满足时才合法：

```text
写 CTRL.start=1 && enable=1 && busy=0
```

合法启动产生一个周期的 `start_o`。非法启动不应改变 M3 状态。建议 M1 负责过滤，M3 只处理已经合法的 `start_i`。

### 3.5 W1P 与 PSLVERR 的规格冲突

规格一处写明 `CTRL.start` 是可写的 W1P，另一处又把“写 RO/W1P”归为 `PSLVERR=1`。二者冲突。实现时应采用能让系统工作的解释：

- 写 `CTRL.start` 是合法操作，写 1 产生单拍脉冲，读回始终为 0。
- 写 RO 字段或未定义地址返回 `PSLVERR=1`。
- 不要因为 W1P 属性而拒绝合法的 start 写入。

在实验报告中记录这一取舍，便于助教检查时说明依据。

### 3.6 `PKT_LEN_EXP=0` 的含义

规格说“若 PKT_LEN_EXP 已配置”才做一致性检查，但复位值为 0。建议约定：

```text
exp_pkt_len == 0：未配置，不检查相等性
exp_pkt_len != 0：要求 pkt_len == exp_pkt_len
```

### 3.7 非法长度必须能结束

`pkt_len=3` 或 `pkt_len=33` 时仍要求 `done=1`，不能按非法长度继续读到越界或永远不结束。建议 M3 读完 Word0 后：

- 置 `length_error=1`。
- 不再访问超出 0～7 的 SRAM 地址。
- 直接完成本帧并进入 DONE。

## 4. Lab1：实现 APB、CSR 和 SRAM

### 4.1 Lab1 的目标

完成 `apb_slave_if`、`packet_sram` 和可复用的 APB 测试环境。Lab1 结束时，即使 M3 还不存在，也应能验证：

- APB 两段式时序正确。
- CSR 默认值、读写属性正确。
- 8 个 PKT_MEM word 能正确写入和读回。
- M3 状态/结果输入可以用 TB stub 注入，再经 APB 读回。

### 4.2 先实现 M2 `packet_sram`

内部存储定义为 `logic [31:0] mem [0:7]`，三个端口行为如下：

- 写口：`apb_wr_en` 有效时，在上升沿执行 `mem[apb_addr] <= apb_wr_data`。
- M3 读口：`proc_rd_en` 有效时，在上升沿执行 `proc_rd_data <= mem[proc_rd_addr]`。
- APB 读口：`apb_rd_en` 有效时，在上升沿执行 `apb_rd_data <= mem[apb_addr]`。

两个读口互不仲裁，可以同拍读取相同或不同地址。M2 不检查 `busy`、包长、类型或校验。

复位是否清空整个 SRAM 并不影响必做功能；若清空，会让仿真更确定，但不要把清空操作写成不可综合的大循环而不理解综合代价。读数据寄存器应在复位时清零。

### 4.3 再实现 M1 `apb_slave_if`

按以下顺序实现，便于逐步仿真：

1. 固定 `PREADY=1`，完成 APB SETUP/ACCESS 识别。
2. 实现 `CTRL`、`CFG`、`IRQ_EN`、`PKT_LEN_EXP` 的寄存器及复位值。
3. 实现 STATUS、RES_*、ERR_FLAG 的只读组合映射。
4. 实现 PKT_MEM 地址译码和写口。
5. 实现 PKT_MEM SETUP 预读与 ACCESS 返回。
6. 最后增加 `PSLVERR`、IRQ 和 RW1C 行为。

地址译码建议显式分区：

```text
0x000～0x028：合法 CSR
0x02C～0x03F：保留，报错
0x040～0x05C：PKT_MEM，且必须 4 字节对齐
0x05D 以上：报错
```

PKT_MEM word 地址计算：

```text
word_index = (PADDR - 12'h040) >> 2
```

还要检查 `PADDR[1:0] == 2'b00`，否则不要把未对齐地址误译码为合法 word。

### 4.4 CSR 的关键行为

- `CTRL.enable`：RW，复位为 0。
- `CTRL.start`：W1P，只有合法启动时产生 `start_o`，读回为 0。
- `CFG.algo_mode`：RW，复位为 1。
- `CFG.type_mask`：RW，复位为 `4'b1111`。
- `STATUS`：由 M3 输入组合形成，不在 M1 重复锁存。
- `RES_*` 和 `ERR_FLAG`：直接映射 M3 输入。
- `IRQ_STA`：内部锁存，写 1 清零。
- `irq_o = done_irq | err_irq`。

中断置位要检测 `done_i` 上升沿，因此 M1 需要保存一拍 `done_i_d`。若软件清中断与新完成事件同拍，建议“事件置位优先于软件清零”，避免丢中断，并在报告中说明优先级。

### 4.5 Lab1 TB 怎么写

至少准备以下 APB task：

```text
reset_dut()
apb_write(addr, data, expected_slverr)
apb_read(addr, data, expected_slverr)
check_equal(name, actual, expected)
```

`apb_write/read` 必须真实驱动 SETUP 和 ACCESS 两拍，不能在一个周期内直接改完所有信号。

推荐测试顺序：

1. `lab1_reset_test`：检查 CTRL、CFG、STATUS、IRQ_EN、PKT_LEN_EXP 默认值。
2. `lab1_csr_rw_test`：逐项写读 RW 字段，并检查保留位读回 0。
3. `lab1_mem_map_test`：向 `0x040～0x05C` 写 8 个不同值，检查 M1 输出写地址和写数据，并通过 APB 读回。
4. `lab1_result_path_test`：TB 对 `res_*_i` 和错误输入赋值，APB 读取对应 CSR。
5. `lab1_error_test`：写 RO、访问保留/未对齐地址、busy 时写内存，检查 `PSLVERR` 和无副作用。
6. `lab1_irq_test`：模拟 done 上升沿、检查 IRQ 置位，再写 IRQ_STA 清零。

### 4.6 Lab1 验收前应保存的波形

- 一次完整 APB 写和 APB 读，包含 PSEL、PENABLE、PWRITE、PADDR、PWDATA、PRDATA、PREADY。
- 连续写 8 个 PKT_MEM word，显示 `pkt_mem_we_o`、`pkt_mem_addr_o`、`pkt_mem_wdata_o`。
- stub 结果到 APB `PRDATA` 的通路。
- 选做项还要显示 `PSLVERR` 和 `irq_o` 的置位/清除。

### 4.7 Lab1 完成判据

- 三个必做测试全部自检 PASS。
- 测试失败时能打印地址、期望值和实际值，而不是只看波形。
- M1、M2 端口名与规格一致，避免 Lab3 集成时改接口。

## 5. Lab2：实现 Packet 处理核

### 5.1 Lab2 的目标

独立完成 M3，不依赖 Lab1 RTL。TB 用一个 8×32-bit 数组模拟 M2 的同步读口。Lab2 结束时，M3 应能处理正常包、非法长度和连续两帧，并保持正确的 busy/done 时序。

### 5.2 建议的内部寄存器

除三态 FSM 外，建议至少包含：

```text
state                 IDLE / PROCESS / DONE
word_index            当前请求的 word 地址
rd_pending/data_valid 同步 SRAM 读流水标志
pkt_len_reg           解析后的长度
pkt_type_reg          解析后的类型
total_words           ceil(pkt_len / 4)
sum_acc               payload 累加和
xor_acc               payload XOR
length/type/chk_error 三类错误暂存
```

M2 是同步读，`mem_rd_addr_o` 发出后，`mem_rd_data_i` 下一拍才有效。FSM 虽然只有三态，但 PROCESS 内必须有 `rd_pending` 或等价流水控制，不能在发地址的同一拍直接消费数据。

### 5.3 推荐处理流程

#### 启动拍

收到 `start_i` 时：

- 清上一帧结果、错误、sum 和 XOR。
- `done_o` 清零，`busy_o` 置 1。
- 请求读取 Word0。
- 进入 PROCESS。

#### Word0 返回拍

按约定字节序解析：

```text
pkt_len  = mem_rd_data_i[31:24]
pkt_type = mem_rd_data_i[23:16]
flags    = mem_rd_data_i[15:8]
hdr_chk  = mem_rd_data_i[7:0]
```

同拍计算三类错误：

- 长度范围：`pkt_len < 4 || pkt_len > 32`。
- 期望长度：`exp_pkt_len_i != 0 && pkt_len != exp_pkt_len_i`。
- 类型格式：必须是 `0x01/0x02/0x04/0x08` 之一。
- 类型掩码：对应 `type_mask_i` 位必须为 1。
- 头校验：`algo_mode_i==1` 时检查 `hdr_chk == pkt_len ^ pkt_type ^ flags`；旁路时 `chk_error=0`。

若长度非法，完成错误结果并进入 DONE。若长度合法且等于 4，也直接进入 DONE。只有存在 payload 时才继续请求 Word1。

#### Payload 处理

`total_words = (pkt_len + 3) / 4`。对 Word1 到最后一个 Word：

- 只累计 Byte4 到 Byte(`pkt_len-1`)。
- 最后一个 word 不满 4 字节时，只处理有效的高位字节。
- `sum_acc` 每次加法保留低 8 位。
- `xor_acc` 对所有有效 payload 字节逐位 XOR。

处理最后一个有效字节后，把结果寄存到 `res_payload_sum_o` 和 `res_payload_xor_o`，再进入 DONE。

#### DONE 状态

- `busy_o=0`。
- `done_o=1` 并持续保持。
- 结果和错误持续保持。
- 下一次 `start_i` 到来时直接开始新帧，并清除旧结果与 done。

不要自动从 DONE 回 IDLE，否则软件可能来不及观察 `done=1`。

### 5.4 类型检查的简单写法

可先判断允许的 one-hot 值，再检查 mask：

```text
0x01 -> type_mask_i[0]
0x02 -> type_mask_i[1]
0x04 -> type_mask_i[2]
0x08 -> type_mask_i[3]
其他 -> type_error
```

这种写法比只用 `$onehot()` 更明确，因为 8-bit 中其他 one-hot 值如 `0x10` 也必须判错。

### 5.5 Lab2 TB 怎么写

内存模型必须模拟一拍同步读延迟。推荐 scoreboard 用独立的参考函数从 byte 数组计算：

```text
expected_len
expected_type
expected_sum
expected_xor
expected_errors
```

必做测试：

1. `lab2_min_packet_test`：长度 4，无 payload。
2. `lab2_normal_packet_test`：长度 8，检查类型和 FSM。
3. `lab2_length_underflow_test`：长度 3，必须报错且正常 done。
4. `lab2_length_overflow_test`：长度 33，不能访问 SRAM 地址 8。
5. `lab2_back_to_back_test`：DONE 状态再次 start，检查 done 清零和新结果覆盖。

选做测试：

6. 非 one-hot 类型和 type_mask 屏蔽。
7. hdr_chk 正确、错误和 `algo_mode=0` 旁路。
8. 长度 5、7、31、32，重点检查最后一个 word 的有效字节。
9. payload sum 溢出，检查 8-bit 截断。

### 5.6 建议加入的断言

- PROCESS 时 `busy_o==1 && done_o==0`。
- DONE 时 `busy_o==0 && done_o==1`。
- `mem_rd_addr_o` 永远不大于 7。
- 非 PROCESS 状态下 `mem_rd_en_o==0`。
- 没有新 start 时，DONE 状态结果保持稳定。
- start 后下一拍进入 busy。

### 5.7 Lab2 完成判据

- 合法包结果自动比对通过。
- 3 和 33 两种非法长度都能在有限周期内 done。
- 连续两帧结果互不污染。
- 波形能清楚展示 `IDLE -> PROCESS -> DONE` 和同步读流水。

## 6. Lab3：顶层集成与端到端验证

### 6.1 Lab3 的目标

把 Lab1 和 Lab2 的 RTL 原样连接起来。Lab3 主要风险不是新算法，而是信号方向、时序和端口语义接错。

### 6.2 顶层连线清单

| 来源 | 目标 | 信号含义 |
| --- | --- | --- |
| M1 `pkt_mem_we_o` | M2 `apb_wr_en` | APB 写 SRAM |
| M1 `pkt_mem_addr_o` | M2 `apb_addr` | M1 读写共享地址 |
| M1 `pkt_mem_wdata_o` | M2 `apb_wr_data` | 写数据 |
| M1 `pkt_mem_re_o` | M2 `apb_rd_en` | APB 读请求 |
| M2 `apb_rd_data` | M1 `pkt_mem_rdata_i` | APB 读数据 |
| M3 `mem_rd_en_o` | M2 `proc_rd_en` | 处理读请求 |
| M3 `mem_rd_addr_o` | M2 `proc_rd_addr` | 处理读地址 |
| M2 `proc_rd_data` | M3 `mem_rd_data_i` | 处理读数据 |
| M1 `start_o` | M3 `start_i` | 启动脉冲 |
| M1 配置输出 | M3 配置输入 | mode、mask、期望长度 |
| M3 状态/结果/错误 | M1 对应输入 | APB 可读状态 |
| M1 `irq_o` | 顶层 `irq_o` | 中断输出 |

`PCLK/PRESETn` 同时连接 M1，并映射到 M2、M3 的 `clk/rst_n`。

顶层不需要给 M1/M3 的读口加仲裁，因为 M2 已有两个独立读口。

### 6.3 集成 TB 的端到端序列

一次完整测试按下面顺序执行：

1. 复位，检查 CSR 默认值。
2. 通过 APB 写 PKT_MEM。
3. 可选：通过 APB 读回 Packet，先确认存储链路正确。
4. 写 CFG、PKT_LEN_EXP 和 IRQ_EN。
5. 写 `CTRL.enable=1`。
6. 写 `CTRL.start=1`。
7. 轮询 STATUS.done，并设置超时，禁止无限等待。
8. 读取 STATUS、RES_* 和 ERR_FLAG。
9. 与软件参考模型比较。
10. 若启用中断，检查并清除 IRQ_STA。

轮询必须有超时，例如 100 个时钟周期。超时应直接 FAIL，并打印 M3 状态、读地址和 STATUS，方便定位卡死原因。

### 6.4 Lab3 测试顺序

1. `int_smoke_test`：最小合法包，验证完整链路。
2. `int_normal_test`：8 字节合法包，检查 len/type/sum/xor。
3. `int_two_packets_test`：两帧长度不同，检查 done 清零和结果覆盖。
4. `int_status_test`：处理期间读取 STATUS，检查 busy/done 编码。
5. `int_busy_write_test`：busy 时写 PKT_MEM，检查 `PSLVERR=1` 且数据不变。
6. `int_irq_test`：完成事件置位 IRQ、APB 清除 IRQ。

### 6.5 集成问题的定位顺序

端到端失败时不要直接改算法，按链路逐级检查：

1. APB 写时 M1 是否发出正确 `pkt_mem_*`。
2. M2 `mem[0:7]` 是否保存了期望值。
3. `start_o` 是否只有一拍，且确实到达 M3。
4. M3 请求地址与 M2 返回数据是否错一拍。
5. M3 结果是否正确产生。
6. M1 的 APB 读 mux 是否返回了该结果。

这能快速区分总线、存储、算法和读回路径四类问题。

### 6.6 Lab3 完成判据

- 合法包可以完成“写包 -> start -> done -> 读结果”的全链路。
- 连续两帧均正确，第二帧不会残留第一帧的 sum、xor 或错误位。
- STATUS 在 PROCESS 和 DONE 阶段读值正确。
- 顶层只有连线，不重复实现子模块逻辑。

## 7. Lab4：回归、覆盖率和最终交付

### 7.1 Lab4 的目标

Lab4 不应再大规模增加 RTL 功能。重点是把 Lab1～3 的测试变成可重复、可统计、可解释的回归系统，并用覆盖率证明测试充分。

### 7.2 建立 testplan

每个需求至少对应一条 testcase。推荐字段：

| testcase | 对应检查点 | 输入摘要 | 期望输出 | 覆盖点 | 结果 |
| --- | --- | --- | --- | --- | --- |
| `int_min_packet` | N-1 | len=4,type=1 | done=1,ok=1 | len_min | PASS/FAIL |
| `int_normal_8B` | N-2 | len=8,4B payload | sum/xor 正确 | len_normal | PASS/FAIL |
| `int_max_packet` | N-3 | len=32 | 完成且地址不越界 | len_max | PASS/FAIL |
| `int_two_packets` | N-4/B-1 | 连续两帧 | done 清零、结果覆盖 | back_to_back | PASS/FAIL |
| `int_len_underflow` | E-1 | len=3 | length_error | len_bad_low | PASS/FAIL |
| `int_len_overflow` | E-2 | len=33 | length_error | len_bad_high | PASS/FAIL |
| `int_bad_type` | E-3 | type=3 | type_error | type_invalid | PASS/FAIL |
| `int_type_mask` | E-4 | mask 屏蔽 | type_error | type_masked | PASS/FAIL |
| `int_bad_checksum` | E-5 | 错 hdr_chk | chk_error | checksum_bad | PASS/FAIL |
| `int_checksum_bypass` | E-6 | mode=0 | chk_error=0 | checksum_bypass | PASS/FAIL |

另外加入 APB 非法地址、RO 写、busy 写保护、IRQ 置位/清除、部分 word 和随机 payload。

### 7.3 回归脚本应完成什么

`make regress` 应自动完成：

1. 清理本次生成文件，但不要删除源文件和历史报告。
2. 编译全部 RTL/TB。
3. 按 `tests.list` 逐条运行，可为每条测试指定 seed。
4. 保存每条测试的独立日志和波形。
5. 汇总 PASS、FAIL、超时和 seed。
6. 只要有一条失败，命令返回非零退出码。

`sim/result_summary.txt` 至少包含：

```text
TOTAL=...
PASS=...
FAIL=...
PASS_RATE=...
FAILED_TESTS=...
```

### 7.4 功能覆盖率建议

代码覆盖率之外，建议建立以下功能覆盖：

- `pkt_len`：3、4、5～31、32、33。
- `pkt_type`：四种合法类型、非 one-hot、mask 屏蔽。
- `algo_mode`：0 和 1。
- `payload_len`：0、非 4 对齐、4 对齐、最大值 28。
- 错误组合：无错误、单错误、多错误同时发生。
- FSM 转移：IDLE->PROCESS、PROCESS->DONE、DONE->PROCESS。
- APB 类型：CSR 读写、MEM 读写、RO 写、未定义地址、未对齐地址。
- 中断：done、error、两者屏蔽、RW1C 清除。

关键 cross 可以选：

```text
pkt_len_range x algo_mode
pkt_type_class x type_mask_result
error_kind x irq_enable
apb_region x read_write
```

不要为了数字盲目建立巨大的 cross；覆盖点应能回答“哪条需求还没测到”。

### 7.5 断言建议

- APB SETUP 到 ACCESS 地址和控制信号保持稳定。
- `PREADY` 始终为 1。
- busy 时 M1 不产生 SRAM 写使能。
- 合法 start 只产生单拍 `start_o`。
- M3 读地址不越界。
- `format_ok == !(length_error || type_error || chk_error)`，在结果有效时成立。
- `irq_o == done_irq || err_irq`。
- DONE 状态无新 start 时，结果保持稳定。

### 7.6 覆盖率闭环方法

1. 先跑全部必做测试，记录初始覆盖率。
2. 对每个未覆盖点判断：缺测试、不可达代码，还是冗余 RTL。
3. 缺测试就补定向 testcase，不要只依赖随机碰撞。
4. 不可达代码优先简化 RTL；确需过滤时登记文件、行号、原因和结论。
5. 重新回归，确认新增测试没有破坏已有功能。
6. 最后合并 UCDB，并在 Questa GUI 现场展示五类覆盖率。

### 7.7 Lab4 完成判据

- `make regress` 一次运行全部 PASS。
- Lab1～3 每个必做检查点至少有一条自动化 testcase。
- testplan 能从需求追踪到测试和结果。
- line、branch、condition、FSM、toggle 五类覆盖率达到目标。
- 任何 coverage exclude 都有登记依据。
- 现场能够解释回归脚本、随机 seed、失败定位和覆盖率缺口。

## 8. 最省返工的实施顺序

按下面顺序推进，前一步通过再进入下一步：

1. 建目录、Makefile 和最小编译目标。
2. 写 `packet_sram`，用极小 TB 验证双读口和写口。
3. 写 M1 的 APB 框架和 RW CSR。
4. 加 M1 的 PKT_MEM 写、SETUP 预读和 APB 读回。
5. 完成 Lab1 必做测试，再做 PSLVERR/IRQ。
6. 写 M3 三态框架和同步读流水。
7. 先跑长度 4，再跑长度 8，最后补边界与错误。
8. 完成 Lab2 自检后再写 `ppa_top`。
9. 集成先跑最小包，再跑连续两帧和异常场景。
10. 冻结 RTL 接口，整理回归和覆盖率。

## 9. 最终验收检查表

### RTL

- [ ] 四个模块文件齐全，端口名与规格一致。
- [ ] 所有时序逻辑使用同一复位极性约定。
- [ ] APB 写副作用只发生在 ACCESS 上升沿。
- [ ] M2 两个读口真正独立。
- [ ] M3 正确处理一拍同步读延迟。
- [ ] 非法长度不会越界或卡死。
- [ ] 下一次 start 会清除旧 done、结果和错误。
- [ ] 顶层仅连线。

### 验证

- [ ] 所有 testcase 自动判定 PASS/FAIL。
- [ ] 每个等待循环都有超时。
- [ ] scoreboard 与 RTL 不共享同一套有缺陷的算法实现。
- [ ] 覆盖正常、异常、边界和连续两帧。
- [ ] 随机测试记录 seed，可复现失败。

### 交付

- [ ] `make smoke`、`make regress`、`make cov` 可运行。
- [ ] `result_summary.txt` 可直接查看通过率。
- [ ] testplan 字段完整并与 testcase 名称一致。
- [ ] 覆盖率报告可在 Questa GUI 打开。
- [ ] 报告记录工具版本、命令、seed 策略和规格歧义处理。

## 10. 评分优先级建议

先拿稳四次实验的必做项，再按依赖关系做选做：

1. Lab1 必做 -> Lab2 必做 -> Lab3 必做。
2. Lab1 PSLVERR -> Lab3 busy 写保护。
3. Lab1 IRQ -> Lab3 中断闭环。
4. Lab2 类型/校验/sum/xor -> Lab4 选做功能回归。
5. 最后做覆盖率过滤登记和 100% 覆盖冲刺。

其中 Lab3/4 权重更高，不能为了 Lab1/2 的选做项拖延集成和回归。最有效的策略是每个 Lab 先形成“可编译、可运行、可自动判定”的最小闭环，再逐项扩展。

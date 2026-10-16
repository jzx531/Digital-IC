# APB 总线协议与 PPA-Lite 项目模块分析

## 1. APB 是什么

APB（Advanced Peripheral Bus）是 AMBA 总线体系中面向低带宽外设的同步总线。它适合寄存器配置、状态读取、中断控制和小容量存储窗口，不强调突发传输和高吞吐量，而强调接口简单、逻辑面积小、时序容易收敛。

APB 一次只完成一个地址的一次读或写。每次传输至少包含两个阶段：

1. **SETUP 阶段**：主设备给出地址、方向和写数据，并选中从设备。
2. **ACCESS 阶段**：主设备拉高 `PENABLE`，从设备在传输完成时返回 `PREADY`，读操作同时返回 `PRDATA`，错误操作返回 `PSLVERR`。

APB 没有 AXI/AHB 中彼此独立的地址通道和数据通道，也没有 burst、ID 或乱序响应。本项目一次 APB 访问就是一次完整的 32-bit CSR 或 SRAM word 访问。

## 2. APB 信号说明

### 2.1 本项目使用的信号

| 信号 | 方向（相对从设备） | 本项目位宽 | 含义 |
| --- | --- | ---: | --- |
| `PCLK` | 输入 | 1 | APB 时钟，所有传输阶段都以它为基准 |
| `PRESETn` | 输入 | 1 | 低有效复位 |
| `PSEL` | 输入 | 1 | 从设备选择，高电平表示当前访问本从设备 |
| `PENABLE` | 输入 | 1 | ACCESS 阶段指示，SETUP 阶段必须为 0 |
| `PWRITE` | 输入 | 1 | 方向，1 表示写，0 表示读 |
| `PADDR` | 输入 | 12 | 字节地址 |
| `PWDATA` | 输入 | 32 | 写数据 |
| `PRDATA` | 输出 | 32 | 读数据，在读 ACCESS 阶段有效 |
| `PREADY` | 输出 | 1 | 完成响应；为 0 时延长 ACCESS 阶段 |
| `PSLVERR` | 输出 | 1 | 错误响应，只在传输完成的 ACCESS 阶段有意义 |

本实验采用 APB 3.0 接口，并使用 `PREADY` 和 `PSLVERR` 完成就绪及错误响应。`PSTRB`、`PPROT` 等 APB4 扩展信号不在本项目接口中，因此本项目只处理完整的 32-bit word 写入，不支持按字节写掩码。

### 2.2 信号稳定性要求

主设备在 SETUP 阶段给出以下控制信息：

```text
PSEL   = 1
PENABLE= 0
PADDR  = 目标地址
PWRITE = 读写方向
PWDATA = 写数据（写操作时）
```

进入 ACCESS 阶段后，主设备将 `PENABLE` 置 1。在该次传输完成前，`PADDR`、`PWRITE`、`PSEL` 以及写操作的 `PWDATA` 必须保持稳定。否则从设备可能在同一次传输中看到互相矛盾的地址或数据。

从设备在 `PSEL && PENABLE && PREADY` 同时为 1 的时钟边沿完成传输：

- 写操作：从设备接收 `PWDATA` 并产生寄存器或存储器写副作用。
- 读操作：主设备采样 `PRDATA`。
- 主设备同时采样 `PSLVERR`，判断该次访问是否出错。

## 3. APB 状态与传输过程

### 3.1 三种逻辑状态

APB 常用三个逻辑状态描述传输：

| 状态 | `PSEL` | `PENABLE` | 含义 |
| --- | ---: | ---: | --- |
| IDLE | 0 | 0 | 当前没有访问 |
| SETUP | 1 | 0 | 提供本次访问的地址、方向和写数据 |
| ACCESS | 1 | 1 | 从设备返回完成、读数据和错误响应 |

状态变化可以写成：

```text
IDLE   -- PSEL=1 ------------------------> SETUP
SETUP  -- 无条件进入 --------------------> ACCESS
ACCESS -- PREADY=0 ----------------------> ACCESS（等待）
ACCESS -- PREADY=1，后续无传输 ----------> IDLE
ACCESS -- PREADY=1，紧接下一笔传输 ------> SETUP
```

需要特别注意：`PENABLE` 不能在 IDLE 阶段直接拉高。一次新传输必须先经历一个 SETUP 周期。

### 3.2 零等待写传输

本项目把 `PREADY` 固定为 1，所以每次传输只需要一个 SETUP 周期和一个 ACCESS 周期：

```text
时钟周期       N（SETUP）          N+1（ACCESS）       N+2
PSEL              1                    1               0
PENABLE           0                    1               0
PWRITE            1                    1               -
PADDR           写地址               保持              -
PWDATA          写数据               保持              -
PREADY            1                    1               1
PSLVERR            -                 0 或 1             -
写副作用           无             ACCESS 边沿发生       无
```

M1 中相应的传输判定是：

```verilog
apb_access = PSEL && PENABLE;
apb_write  = apb_access && PWRITE;
```

因此不能只看到 `PSEL && PWRITE` 就写寄存器，否则同一笔传输会在 SETUP 和 ACCESS 两个周期重复写入。

### 3.3 零等待读传输

普通 CSR 可以直接组合译码：

```text
时钟周期       N（SETUP）          N+1（ACCESS）       N+2
PSEL              1                    1               0
PENABLE           0                    1               0
PWRITE            0                    0               -
PADDR           读地址               保持              -
PRDATA             -              有效读数据            -
PREADY             1                    1               1
PSLVERR             -                0 或 1              -
```

主设备在 ACCESS 结束边沿采样 `PRDATA`。本项目的 M1 仅在 `PSEL && PENABLE && !PWRITE` 时驱动有效的寄存器读数据，其他阶段将 `PRDATA` 置 0。

### 3.4 等待状态

通用 APB 从设备可以在 ACCESS 阶段把 `PREADY` 拉低来插入等待周期。等待期间：

- 主设备保持 `PSEL=1`、`PENABLE=1`。
- 地址、方向和写数据保持不变。
- 从设备准备好后将 `PREADY` 拉高，当前 ACCESS 才结束。

本项目没有等待状态：

```verilog
assign PREADY = 1'b1;
```

所以本项目每次传输固定占两个时钟周期，M1 不能依赖延长 ACCESS 来等待 M2 返回数据。

### 3.5 连续传输

一笔 ACCESS 完成后，如果主设备马上访问下一地址，可以让 `PSEL` 保持为 1，但必须将 `PENABLE` 拉回 0，进入下一笔传输的 SETUP：

```text
SETUP(A) -> ACCESS(A) -> SETUP(B) -> ACCESS(B)
PENABLE:      0      ->     1     ->    0     ->    1
```

即使连续两次访问同一个地址，也必须重新经过 SETUP，不能让 `PENABLE` 一直为 1 并暗中改变地址。

### 3.6 错误响应

`PSLVERR` 表示当前传输完成了，但访问本身不合法。它不是“停止时钟”或“重试”信号。主设备仍在 `PREADY=1` 的 ACCESS 边沿结束这次访问，然后根据 `PSLVERR` 处理错误。

本项目以下情况返回错误：

- 写只读寄存器，例如 `STATUS`、`RES_*` 或 `ERR_FLAG`。
- 访问保留或未定义地址。
- 访问未按 4 字节对齐的 PKT_MEM 地址。
- `busy_i=1` 时写 PKT_MEM。

错误写入必须没有副作用。例如 busy 期间写 PKT_MEM 时，`PSLVERR=1` 且 M2 的写使能保持为 0。

## 4. 本项目的 APB 地址模型

### 4.1 地址是字节地址

`PADDR` 表示字节地址，而每次数据访问宽度是 32 bit，也就是 4 字节。因此合法 word 地址间隔为 4：

```text
0x040, 0x044, 0x048, 0x04C, 0x050, 0x054, 0x058, 0x05C
```

32-bit 对齐要求等价于：

```verilog
PADDR[1:0] == 2'b00
```

如果不检查低两位，`0x040`、`0x041`、`0x042` 和 `0x043` 的 `PADDR[4:2]` 都相同，都会错误地访问 M2 的 Word 0。

### 4.2 地址空间

| 地址 | 对象 | 访问属性 |
| --- | --- | --- |
| `0x000` | CTRL | `enable` 为 RW，`start` 为 W1P |
| `0x004` | CFG | RW |
| `0x008` | STATUS | RO |
| `0x00C` | IRQ_EN | RW |
| `0x010` | IRQ_STA | RW1C |
| `0x014` | PKT_LEN_EXP | RW |
| `0x018`～`0x028` | RES_*、ERR_FLAG | RO |
| `0x02C`～`0x03F` | 保留 | 访问报错 |
| `0x040`～`0x05C` | PKT_MEM Word 0～7 | 32-bit 对齐读写 |
| `0x05D` 及以上 | 保留或未定义 | 访问报错 |

寄存器属性不是 APB 协议自身规定的，而是本从设备的功能定义：

- **RW**：写入后保存，允许读回。
- **RO**：只能读取，写入返回 `PSLVERR`。
- **W1P**：写 1 产生一个时钟周期的脉冲，不保存 1，读回为 0。
- **RW1C**：可以读取当前状态，向某位写 1 清除该位，写 0 保持。

## 5. M1：APB 协议终结点和内部桥接器

M1 `apb_slave_if` 是三个模块中唯一直接理解 APB 协议的模块。APB Master 实际上只与 M1 交互；M2 和 M3 都通过 M1 映射到 APB 地址空间。

### 5.1 APB 阶段识别

M1 将总线组合成四个内部条件：

```verilog
apb_setup  = PSEL && !PENABLE;
apb_access = PSEL &&  PENABLE;
apb_write  = apb_access &&  PWRITE;
apb_read   = apb_access && !PWRITE;
```

它们的用途不同：

| 条件 | M1 中的用途 |
| --- | --- |
| `apb_setup` | 提前向同步 SRAM 发出 APB 读请求 |
| `apb_access` | 判断 `PRDATA`、`PSLVERR` 所在的有效阶段 |
| `apb_write` | 在 ACCESS 边沿更新 CSR 或写 M2 |
| `apb_read` | 在 ACCESS 阶段将 CSR/M2 数据送到 `PRDATA` |

### 5.2 M1 对 CSR 的处理

对 RW 寄存器，M1 在 `apb_write` 有效的上升沿保存 `PWDATA` 中定义的位。保留位不保存，读回为 0。

`CTRL.start` 是 W1P。写 `CTRL` 时，只有以下条件同时满足才产生 `start_o`：

```text
PWDATA[1] = 1       请求 start
PWDATA[0] = 1       enable=1
busy_i    = 0       M3 当前空闲
```

`start_o` 默认在下一拍清零，所以 M3 只看到一个周期的启动脉冲。对本项目中的规格冲突，采用“W1P 可以合法写入”的解释；否则软件无法启动 M3。

M3 的状态与结果不在 M1 中重复保存。M1把 `busy_i`、`done_i`、结果值和错误标志组合映射到 `STATUS`、`RES_*` 和 `ERR_FLAG`。这样软件通过 APB 读取 M1，实际观察到的是 M3 当前保持的输出。

### 5.3 M1 对 M2 写访问的转换

当 APB Master 写 `0x040～0x05C` 时，M1把 APB 信号转换成 M2 的简单同步写口：

```text
APB PADDR[4:2]  -> pkt_mem_addr_o
APB PWDATA      -> pkt_mem_wdata_o
合法 apb_write  -> pkt_mem_we_o
```

M2 的 word 编号为：

```text
word_index = (PADDR - 0x040) / 4
```

因为基地址 `0x040` 的 `PADDR[4:2]` 本身为 0，所以当前 RTL 直接使用 `PADDR[4:2]`。busy 写保护也由 M1 完成：

```text
pkt_mem_we_o = apb_write && 地址合法 && !busy_i
```

M2 不知道 `busy_i`，也不负责返回 `PSLVERR`。

### 5.4 M1 对 M2 读访问的转换

M2 是同步读存储器。读使能在某个上升沿被采样后，读数据寄存器才更新。如果 M1 等到 ACCESS 阶段再拉高读使能，数据会在 ACCESS 结束后才出现，与本项目 `PREADY=1` 的零等待约定冲突。

因此 M1 在 SETUP 阶段提前发出读请求：

```verilog
pkt_mem_rd_en_o = apb_setup && !PWRITE && pkt_mem_addr_valid;
```

完整路径是：

```text
SETUP：PADDR 有效，M1 拉高 pkt_mem_rd_en_o
   |
   | SETUP 结束上升沿
   v
M2：pkt_mem_rd_data_i <= mem[pkt_mem_rd_addr_o]
   |
   v
ACCESS：M1 将 pkt_mem_rd_data_i 组合送到 PRDATA，PREADY=1
```

这是本项目中 APB 与同步 SRAM 时序衔接的核心。它依赖 APB 规定的“SETUP 到 ACCESS 地址保持稳定”。

### 5.5 M1 的错误与中断

M1在 ACCESS 阶段根据读写方向和地址合法性产生 `PSLVERR`。对于合法访问，`PSLVERR=0`；对于非法访问，它只报告错误，不执行写副作用。

中断不是 APB 传输信号，而是从设备额外提供给处理器的事件信号：

1. M1 保存上一拍 `done_i`，检测 `done_i` 上升沿。
2. 若 `done_irq_en=1`，置位 `IRQ_STA.done_irq`。
3. 若同时存在错误且 `err_irq_en=1`，置位 `IRQ_STA.err_irq`。
4. `irq_o = done_irq || err_irq`。
5. 软件通过 APB 向 `IRQ_STA` 写 1 清除相应中断位。

## 6. M2：被 APB 映射的同步 SRAM

M2 `packet_sram` 不是 APB 从设备。它没有 `PSEL`、`PENABLE`、`PREADY` 或 `PSLVERR`，只提供本地存储器端口。

### 6.1 三个端口

M2 是 8×32-bit、1 写 2 读的存储器：

| 端口 | 使用者 | 用途 |
| --- | --- | --- |
| 写端口 `wr_en/wr_addr/wr_data` | M1 | APB Master 写 PKT_MEM |
| 读端口 0 `rd_en/rd_addr/rd_data` | M3 | 包处理期间顺序读取数据 |
| 读端口 1 `rd_en_1/rd_addr_1/rd_data_1` | M1 | APB Master 读回 PKT_MEM |

两个读口互相独立，因此 M1 和 M3 可以同拍读取相同或不同 word，不需要顶层仲裁。

### 6.2 同步端口时序

写端口在上升沿执行：

```verilog
if (wr_en)
  mem[wr_addr] <= wr_data;
```

读端口也是寄存器输出：

```verilog
if (rd_en_1)
  rd_data_1 <= mem[rd_addr_1];
```

所以 M2 的“读一拍延迟”是 M1 必须在 APB SETUP 阶段预读的根本原因。M2 只认本地使能和地址，不判断 APB 阶段、CSR 地址、地址对齐、busy 或 Packet 合法性。

## 7. M3：通过 CSR 控制和观察的处理引擎

M3 `packet_proc_core` 同样不是 APB 从设备。它不直接接收 `PADDR/PWRITE/PWDATA`，而是通过 M1 的字段接口间接受软件控制。

### 7.1 APB 到 M3 的控制路径

```text
APB Master 写 CTRL/CFG/PKT_LEN_EXP
             |
             v
M1 保存 CSR，并输出字段信号
             |
             +--> start_o        -> M3 start_i
             +--> algo_mode_o    -> M3 algo_mode_i
             +--> type_mask_o    -> M3 type_mask_i
             +--> exp_pkt_len_o  -> M3 exp_pkt_len_i
```

软件不能通过 APB 直接改变 M3 的 FSM 状态。它只能配置寄存器并写 `CTRL.start=1`，由 M1检查 enable 和 busy 后产生合法启动脉冲。

### 7.2 M3 读取 M2 的路径

M3 启动后通过 M2 的专用读口读取 Packet：

```text
M3 mem_rd_en_o/mem_rd_addr_o
             |
             v
M2 读端口 0（同步读，一拍延迟）
             |
             v
M3 mem_rd_data_i
```

这条路径完全位于 APB 总线之外。APB Master 只负责先把 Packet 写进 M2，再启动 M3。M3 的 PROCESS 状态必须自行处理 M2 的一拍读延迟。

### 7.3 M3 到 APB 的状态路径

M3 完成解析后保持以下输出：

```text
busy_o, done_o, format_ok_o
length_error_o, type_error_o, chk_error_o
res_pkt_len_o, res_pkt_type_o
res_payload_sum_o, res_payload_xor_o
```

这些信号连接回 M1 的对应输入。软件读取 M1 的 `STATUS`、`RES_*` 和 `ERR_FLAG` 时，M1将它们编码到 `PRDATA`。路径为：

```text
M3 结果/状态 -> M1 CSR 读复用 -> APB PRDATA -> APB Master
```

`done_o` 在 DONE 状态保持为 1，而不是一个脉冲，这样软件轮询 STATUS 时不容易错过。M1另外检测其上升沿，用于生成一次完成事件并锁存中断。

## 8. M1、M2、M3 与 APB 的关系总结

| 模块 | 是否直接实现 APB | 在 APB 地址空间中的表现 | 主要责任 |
| --- | --- | --- | --- |
| M1 `apb_slave_if` | 是 | 整个从设备接口 | 识别 SETUP/ACCESS、译码、CSR、错误响应、中断、桥接 M2/M3 |
| M2 `packet_sram` | 否 | `0x040～0x05C` PKT_MEM 窗口 | 保存 Packet，提供一个写口和两个同步读口 |
| M3 `packet_proc_core` | 否 | CTRL/CFG 配置和 STATUS/RES/ERR 状态寄存器 | 解析 Packet、检查格式、计算结果、产生 busy/done/error |
| `ppa_top` | 只透传 | 顶层 APB 从设备引脚 | 连接三个模块并分发时钟/复位，不增加协议状态 |

可以把整个系统理解成：

```text
                         +----------------------+
APB Master <------------>| M1：APB 从机/桥接器 |
                         +-----+-----------+----+
                               |           |
                   PKT_MEM窗口 |           | CSR字段与状态
                               v           v
                         +-----------+  +-----------+
                         | M2：SRAM  |  | M3：处理器 |
                         +-----+-----+  +-----+-----+
                               ^              |
                               +--------------+
                                  专用同步读口
```

APB 协议终止在 M1。M1之后的 `pkt_mem_*`、`mem_rd_*`、`start/busy/done` 都是项目内部接口，不应再套用 `PSEL/PENABLE/PREADY` 的规则。

## 9. 一次完整业务操作如何穿过三个模块

### 9.1 写入 Packet

1. APB Master 对 `0x040` 发起 SETUP。
2. 下一拍进入 ACCESS。
3. M1确认地址对齐且 `busy_i=0`，拉高 `pkt_mem_we_o`。
4. M2在 ACCESS 结束上升沿写入 Word 0。
5. Master继续用 `0x044`、`0x048` 等地址写 payload。

### 9.2 配置并启动

1. Master写 CFG、PKT_LEN_EXP 和 IRQ_EN。
2. Master写 `CTRL=32'h0000_0001`，设置 enable。
3. Master写 `CTRL=32'h0000_0003`，请求 start。
4. M1在合法 ACCESS 边沿产生一拍 `start_o`。
5. M3接收 `start_i`，进入 PROCESS 并通过自己的 M2 读口读取 Packet。

### 9.3 获取结果

1. M3完成后拉低 busy、保持 done，并保持结果和错误输出。
2. M1把这些信号映射到 STATUS、RES_* 和 ERR_FLAG。
3. Master通过普通 APB 读访问获取结果。
4. 若使能中断，M1在 done 上升沿锁存 IRQ_STA 并拉高 `irq_o`。
5. Master向 IRQ_STA 对应位写 1，M1清除中断锁存。

## 10. 验证时应重点观察的协议规则

1. 每笔访问都必须按 `SETUP -> ACCESS` 两拍驱动。
2. SETUP 到 ACCESS 期间地址、方向和写数据必须保持稳定。
3. CSR 和 PKT_MEM 写副作用只能在 ACCESS 边沿发生一次。
4. `PRDATA` 和 `PSLVERR` 应在 ACCESS 阶段采样。
5. PKT_MEM 读请求应在 SETUP 阶段到达 M2，读数据在 ACCESS 阶段返回。
6. `0x040～0x05C` 只有低两位为 `00` 的地址合法。
7. busy 时写 PKT_MEM 应同时满足 `PSLVERR=1` 和 `pkt_mem_we_o=0`。
8. `start_o` 只能保持一个时钟周期。
9. M3 的 M2 读口与 M1 的 APB 读口独立，不应错误增加仲裁。
10. 连续传输之间必须重新出现一个 `PENABLE=0` 的 SETUP 周期。


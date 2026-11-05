# GitHub 热门数字 IC 验证项目推荐

> 数据快照：2026-11-01。Star 数为 GitHub 近似值，只用于反映社区关注度，不代表项目质量的绝对排名。

## 如何选择

- 想入门 RTL 自动化测试：先看 cocotb，再给一个 FIFO、APB 或 AXI-Lite 模块补齐测试。
- 想走 SystemVerilog/UVM：先读 UVM Core，再学习 CORE-V-Verif 或 Ibex 的真实环境。
- 想做 CPU 验证：重点看 riscv-dv、Ibex、CORE-V-Verif。
- 想做 SoC 级验证：OpenTitan 最完整，但体量很大，适合进阶。
- 想补形式验证：从 SymbiYosys 的小例子开始，再读 wb2axip 的总线属性。

## 推荐清单

| 项目 | 方向 | 主要技术 | 热度 | 难度 |
| --- | --- | --- | ---: | --- |
| [lowRISC/OpenTitan](https://github.com/lowRISC/opentitan) | 安全 SoC 全流程验证 | SystemVerilog、UVM、SVA、C/C++ | ~3.7k stars | 高 |
| [lowRISC/Ibex](https://github.com/lowRISC/ibex) | RISC-V CPU 验证 | SV、UVM、riscv-dv、ISS 对比 | ~2.1k | 中高 |
| [OpenHW Group/CORE-V-Verif](https://github.com/openhwgroup/core-v-verif) | CORE-V CPU 功能验证 | UVM、随机指令、参考模型、覆盖率 | ~736 | 高 |
| [CHIPS Alliance/riscv-dv](https://github.com/chipsalliance/riscv-dv) | RISC-V 随机指令生成 | SystemVerilog、Python、UVM | ~1.4k | 中高 |
| [PULP Platform/axi](https://github.com/pulp-platform/axi) | AXI IP 与验证基础设施 | SystemVerilog、AXI、断言、随机测试 | ~1.7k | 中 |
| [cocotb/cocotb](https://github.com/cocotb/cocotb) | Python RTL 验证框架 | Python、协程、仿真器接口 | ~2.6k | 低中 |
| [pyuvm/pyuvm](https://github.com/pyuvm/pyuvm) | Python UVM | Python、cocotb、UVM 思想 | ~571 | 中 |
| [ZipCPU/wb2axip](https://github.com/ZipCPU/wb2axip) | 总线桥与形式验证 | Verilog、AXI/Wishbone、SVA/Formal | ~713 | 中高 |
| [YosysHQ/sby](https://github.com/YosysHQ/sby) | 开源形式验证流程 | SymbiYosys、Yosys、SMT/SAT | ~560 | 中 |
| [Accellera/uvm-core](https://github.com/accellera-official/uvm-core) | IEEE UVM 官方参考实现 | SystemVerilog、UVM | ~156 | 中高 |
| [VUnit/VUnit](https://github.com/VUnit/vunit) | HDL 单元测试 | VHDL、SystemVerilog、Python | ~853 | 低中 |
| [Verilator/Verilator](https://github.com/verilator/verilator) | 仿真、Lint 与 CI | SystemVerilog、C++、Python | ~4.0k | 中 |
| [chipsalliance/Surelog](https://github.com/chipsalliance/Surelog) | SV 前端与 UHDM | SystemVerilog、C++、VPI、UHDM | ~476 | 高 |
| [google/verible](https://github.com/google/verible) | SV 格式化、Lint 和语言服务 | SystemVerilog、C++ | ~2.0k | 低中 |

## 项目介绍与练习建议

### 1. OpenTitan

OpenTitan 是开源硅信任根 SoC。仓库不仅有 RTL，还包含 UVM 环境、agents、scoreboard、随机测试、软件测试、覆盖率配置和回归基础设施，是观察工业级 SoC 验证组织方式的好样本。

建议练习：选择 UART、GPIO、SPI Device 等单个 IP，阅读 `hw/ip/*/dv`，画出 DUT、agent、scoreboard 和寄存器模型的连接图，再新增一个定向 sequence。不要一开始尝试运行整个 SoC 回归。

### 2. Ibex

Ibex 是小型 RV32 RISC-V 核，验证成熟度高。项目结合随机指令、ISS 对比、形式验证和定向测试，比大型 SoC 更适合学习 CPU 验证闭环。

建议练习：运行一个基础仿真，跟踪一条指令从生成、执行到 signature/ISS 比对的路径；随后加入一个非法指令或异常场景测试。

### 3. CORE-V-Verif

这是 OpenHW Group 为 CORE-V 系列 CPU 建立的功能验证工程，重点在 UVM testbench、RISC-V 随机程序、参考模型和覆盖率。它更接近独立验证团队维护的仓库结构。

建议练习：以 CV32E40P 为目标，理解 test、virtual sequence、RVFI/ISS 比对和 coverage model 的分工，并尝试新增一个 CSR 访问场景。

### 4. riscv-dv

riscv-dv 是广泛使用的 RISC-V 随机指令生成器。它负责产生满足约束的汇编程序，本身不是完整 CPU testbench，通常与 RTL 仿真器和 Spike、OVPsim 等 ISS 组合使用。

建议练习：修改 instruction stream 和 CSR 约束，生成一批程序；再接入 Ibex 或自己的 RISC-V 核完成差分验证。

### 5. PULP AXI

该仓库同时提供可综合 AXI 模块和验证基础设施，适合学习 AXI4/AXI4-Lite/AXI-Stream 的事务、背压、乱序和原子操作。相比只读协议文档，它能直接展示真实边界条件。

建议练习：选 AXI-Lite 模块建立最小仿真，加入随机 `ready` 背压、非法地址和并发读写；用 assertion 检查 VALID/READY 稳定性。

### 6. cocotb

cocotb 使用 Python 驱动 HDL 仿真，适合快速建立测试、参考模型和 CI。它不能自动替代 UVM，但很适合个人项目、算法模块和开源仿真器环境。

建议练习：为同步 FIFO 编写驱动、monitor、Python reference model 和随机回归，并在 GitHub Actions 中使用 Verilator 或 Icarus Verilog运行。

### 7. pyuvm

pyuvm 在 Python 中实现 UVM 的 component、phase、sequence、factory 和 objection 等概念，底层通常配合 cocotb。适合已经理解 Python、又想学习 UVM 架构的人。

建议练习：把 cocotb FIFO 测试重构为 sequencer、driver、monitor、scoreboard 和 coverage 层次，比较它与 SV UVM 的差异。

### 8. wb2axip

项目包含 Wishbone/AXI 桥、crossbar、DMA 等模块，并以形式属性检查总线协议。它的价值主要在形式验证思路，不应只把它当 IP 库使用。

建议练习：阅读 AXI-Lite formal property，故意在一个简单 slave 中引入 VALID/READY 错误，观察形式工具给出的 counterexample。

### 9. SymbiYosys

SymbiYosys 是 Yosys 形式验证流程的前端，可调用不同求解器完成 BMC、prove、cover 等任务。它适合建立无需商业 EDA 的形式验证练习环境。

建议练习：从计数器、FIFO 开始写 safety property 和 cover property，再检查复位、溢出、上下溢等边界条件。

### 10. UVM Core

这是 Accellera 官方 UVM 参考实现，适合查规范行为、phase、factory、RAL 和 TLM 的实现细节。它是基础库，不是开箱即用的 DUT 验证项目。

建议练习：遇到 objection、factory override 或 RAL 行为不清楚时，以该仓库源码和 IEEE 1800.2 文档交叉核对；不要把通读整个库当作入门任务。

### 11. VUnit

VUnit 面向 VHDL/SystemVerilog 单元测试，强调可重复运行、测试发现和 CI。适合验证小型 RTL 单元，也适合 VHDL 项目。

建议练习：为仲裁器或 UART 波特率发生器建立参数化测试，并把不同参数组合加入自动回归。

### 12. Verilator

Verilator 是高性能开源 SystemVerilog 仿真器和 Lint 工具。学习它的重点不是修改仿真器源码，而是用它建立可移植的 lint、仿真和 CI 流程。

建议练习：对个人 RTL 开启较严格 warning，将 warning 当作 CI failure；使用 C++ 或 cocotb testbench 完成可重复回归。

### 13. Surelog

Surelog 是 SystemVerilog 2017 的预处理、解析和 elaboration 前端，并输出 UHDM。适合希望研究 EDA 前端、代码分析或自定义验证工具的人，不适合作为第一个验证项目。

### 14. Verible

Verible 提供 SystemVerilog formatter、style linter 和 language server。把它加入工程能统一风格、尽早发现低级问题，并让验证代码更适合团队协作。

## 推荐学习路线

### 路线 A：总线与模块验证

1. 用 cocotb 验证 FIFO、UART 或 APB slave。
2. 在 PULP AXI 中学习 VALID/READY、背压和并发访问。
3. 用 SymbiYosys 或 wb2axip 属性检查协议不变量。
4. 将 lint、仿真和形式验证接入 CI。

### 路线 B：SystemVerilog/UVM

1. 先完成一个小型 APB/AXI-Lite UVM testbench。
2. 用 UVM Core 核对 phase、factory、TLM 和 RAL 行为。
3. 阅读 CORE-V-Verif 的环境组织方式。
4. 最后选择 OpenTitan 的一个 IP 增加 sequence、check 和 coverage。

### 路线 C：CPU 验证

1. 学习 RISC-V ISA、异常、中断和 CSR。
2. 使用 riscv-dv 生成随机程序。
3. 在 Ibex/CORE-V-Verif 中观察 RTL 与 ISS 差分验证。
4. 增加功能覆盖率，并针对 coverage hole 编写定向测试。

## 选择项目时的注意事项

- Star 高不代表容易运行。OpenTitan、CORE-V-Verif 需要较完整的 Linux/EDA 环境。
- 先确认仿真器支持范围。开源仿真器对完整 UVM 的兼容性仍可能与商业工具不同。
- 仓库中的脚本、锁定版本和安装文档应优先于自行猜测依赖版本。
- 做作品集时，重点展示新增的 test、assertion、coverage、bug 和 CI 结果，而不是只展示成功克隆和运行仓库。

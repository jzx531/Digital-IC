# GitHub 热门嵌入式与嵌入式 Linux 项目推荐

> 数据快照：2026-11-01。Star 数为 GitHub 近似值。部分 Linux 项目的 GitHub 仓库是官方代码的镜像，文中已单独说明。

## 快速选择

- 有 ESP32：优先 ESP-IDF，完成 Wi-Fi、FreeRTOS、外设和 OTA 综合项目。
- 有 STM32、nRF 或其他 MCU：优先 Zephyr、FreeRTOS 或 RT-Thread。
- 想理解 POSIX 风格 RTOS：看 Apache NuttX。
- 想进入嵌入式 Linux BSP：按 U-Boot -> Kernel/Bootlin -> Buildroot -> 驱动的顺序学习。
- 想做路由器或网关：看 OpenWrt。
- 想做量产升级：看 SWUpdate，并设计 A/B 分区和断电恢复。

## MCU、RTOS 与固件项目

| 项目 | 方向 | 适合练习 | 热度 | 难度 |
| --- | --- | --- | ---: | --- |
| [Espressif/ESP-IDF](https://github.com/espressif/esp-idf) | ESP32 官方 SDK | Wi-Fi/BLE、FreeRTOS、OTA、低功耗 | ~19.4k stars | 中 |
| [Zephyr Project](https://github.com/zephyrproject-rtos/zephyr) | 跨平台 RTOS | 设备树、驱动、网络、RTOS 子系统 | ~17.0k | 中高 |
| [RT-Thread](https://github.com/RT-Thread/rt-thread) | IoT RTOS | BSP、组件、FinSH、网络与 GUI | ~12.3k | 中 |
| [RIOT OS](https://github.com/RIOT-OS/RIOT) | 低功耗 IoT OS | IPv6、6LoWPAN、传感网络 | ~5.8k | 中 |
| [FreeRTOS Kernel](https://github.com/FreeRTOS/FreeRTOS-Kernel) | RTOS 内核 | task、queue、semaphore、调度 | ~4.6k | 低中 |
| [Apache NuttX](https://github.com/apache/nuttx) | POSIX 风格 RTOS | 文件系统、驱动、网络、NSH | ~4.1k | 中高 |
| [Raspberry Pi Pico Examples](https://github.com/raspberrypi/pico-examples) | RP2040/RP2350 示例 | PIO、DMA、USB、多核、外设 | ~4.0k | 低中 |
| [ThrowTheSwitch/Unity](https://github.com/ThrowTheSwitch/Unity) | C 单元测试 | 驱动与业务逻辑的主机侧测试 | ~5.4k | 低 |
| [ThrowTheSwitch/Ceedling](https://github.com/ThrowTheSwitch/Ceedling) | C 测试构建与 Mock | Unity、CMock、覆盖率、CI | ~859 | 低中 |

### ESP-IDF

ESP-IDF 是乐鑫官方开发框架，包含 FreeRTOS、驱动、网络协议栈、安全启动、Flash 加密和 OTA。它适合做一块板上能展示完整功能的项目。

推荐项目：实现支持 Wi-Fi 配网、MQTT、传感器采集、NVS 参数保存、看门狗和双分区 OTA 的环境监测节点，并加入异常重启和掉线恢复测试。

### Zephyr

Zephyr 支持多种架构和开发板，设备树、Kconfig、驱动模型和子系统结构与嵌入式 Linux 有相似之处，适合作为 MCU 到 Linux 的过渡。

推荐项目：给一块受支持开发板增加自定义传感器驱动，通过 work queue 周期采样，使用 shell 和 logging 调试，再通过 BLE 或 MQTT 上报。

### RT-Thread

RT-Thread 中文社区活跃，包含 RTOS 内核、设备框架、网络栈、软件包和图形组件。对国内 MCU 岗位和国产芯片 BSP 学习很实用。

推荐项目：移植一块 STM32 BSP，接入 SPI Flash、文件系统、FinSH 和网络组件；记录启动流程、内存占用和线程栈使用情况。

### RIOT

RIOT 面向资源受限 IoT 设备，网络协议和低功耗场景是其重点。适合对 6LoWPAN、CoAP 和传感网络感兴趣的人。

推荐项目：用两块开发板建立 CoAP 节点，测量不同唤醒周期下的延迟和功耗，并分析丢包重传。

### FreeRTOS Kernel

该仓库只包含 FreeRTOS 内核，适合学习调度、任务通知、queue、semaphore 和 software timer。完整板级示例通常还需要芯片厂商 SDK 或 FreeRTOS 主仓库。

推荐项目：实现生产者/消费者、ISR 到 task 通知、优先级反转复现与 mutex 修复，并用运行时统计观察 CPU 占用。

### Apache NuttX

NuttX 提供较完整的 POSIX 接口、驱动模型、文件系统、网络和 NSH shell，常被称为“微型 Linux 风格 RTOS”。

推荐项目：在受支持开发板上完成字符设备驱动、mount 文件系统、NSH 命令和 TCP/UDP 服务，理解 `open/read/write/ioctl` 如何落到驱动层。

### Raspberry Pi Pico Examples

官方示例覆盖 GPIO、PIO、DMA、ADC、PWM、USB 和多核。它适合快速建立裸机和 SDK 基础，但作品集不应只停留在运行单个示例。

推荐项目：使用 PIO + DMA 采集或生成一个自定义时序协议，并通过 USB CDC 输出统计结果。

### Unity 与 Ceedling

Unity 是轻量级 C 单元测试框架，Ceedling 在其上提供构建、CMock 和覆盖率集成。它们适合把硬件无关逻辑放到 PC 上高速测试。

推荐项目：把传感器驱动分成总线适配层和解析层，mock I2C/SPI 访问，覆盖正常数据、CRC 错误、超时和边界值。

## 嵌入式 Linux 项目

| 项目 | 方向 | 适合练习 | 热度 | 难度 |
| --- | --- | --- | ---: | --- |
| [OpenWrt](https://github.com/openwrt/openwrt) | 路由器/网关发行版 | 网络、软件包、交叉编译、设备支持 | ~29.0k stars | 中高 |
| [systemd](https://github.com/systemd/systemd) | Linux 系统与服务管理 | service、启动依赖、日志、设备管理 | ~17.0k | 高 |
| [U-Boot](https://github.com/u-boot/u-boot) | Bootloader | 启动链、设备树、存储、网络启动 | ~5.3k | 中高 |
| [Buildroot](https://github.com/buildroot/buildroot) | 精简 Linux 系统构建 | toolchain、kernel、rootfs、package | ~3.7k | 中 |
| [Linux Test Project](https://github.com/linux-test-project/ltp) | Linux 内核/系统调用测试 | 回归测试、稳定性、内核验证 | ~2.6k | 中高 |
| [BusyBox 镜像](https://github.com/mirror/busybox) | 精简用户空间 | shell、基础命令、initramfs | ~2.2k | 中 |
| [SWUpdate](https://github.com/sbabic/swupdate) | 嵌入式 Linux OTA | A/B 更新、签名、回滚、断电恢复 | ~1.9k | 中高 |
| [Bootlin Training Materials](https://github.com/bootlin/training-materials) | 内核与嵌入式 Linux 实验 | Kernel、驱动、Buildroot、Yocto | ~832 | 低到高 |
| [Yocto Poky](https://github.com/yoctoproject/poky) | 可维护 Linux 发行版构建 | BitBake、layer、recipe、SDK | ~479 | 高 |

### OpenWrt

OpenWrt 是面向路由器和嵌入式网络设备的 Linux 发行版，包含构建系统、包管理、网络配置和大量设备支持。GitHub 仓库是官方 Git 的镜像，但仍接受通过其流程提交的 PR。

推荐项目：为 x86_64 虚拟机或支持的路由器构建镜像，增加自定义 package 和 procd 服务，再实现防火墙、VLAN、WireGuard 或 MQTT 网关功能。

### U-Boot

U-Boot 是最常见的嵌入式 Bootloader 之一。学习重点包括 SPL、DRAM 初始化之后的启动阶段、环境变量、设备树、MMC/NAND 和网络启动。

推荐项目：在 QEMU 或开发板上完成 TFTP/NFS 启动，修改 bootcmd，并跟踪从 U-Boot 到 Linux kernel 的参数和设备树传递。

### Buildroot

Buildroot 能较快生成交叉工具链、内核、Bootloader 和 root filesystem，适合学习最小 Linux 系统。GitHub 仓库是镜像，官方开发仓库在 GitLab。

推荐项目：为 QEMU ARM64 或实际开发板生成系统，增加自定义 package、overlay、system service 和只读 rootfs，并记录可复现配置。

### Yocto/Poky

Poky 是 Yocto Project 的参考发行版，适合需要分层维护、多产品复用和长期升级的工程。它比 Buildroot 更复杂，不建议作为第一次 Linux 构建体验。

推荐项目：建立独立 meta-layer，添加 application recipe、systemd service 和 image recipe，再生成 SDK 给应用开发使用。GitHub 仓库是官方代码镜像。

### SWUpdate

SWUpdate 为嵌入式 Linux 提供可靠升级框架，支持镜像、包、签名、不同存储后端及多种升级策略。

推荐项目：在 QEMU 或双分区板卡实现签名的 A/B 升级，设计 bootcount、健康检查、自动回滚和升级中断电测试。

### Linux Test Project

LTP 包含大量系统调用和内核功能测试。它更适合系统验证、BSP 稳定性和版本升级回归，而不是应用功能开发。

推荐项目：在自制 Buildroot 镜像中裁剪并运行一组 syscall、filesystem 和 memory 测试，整理失败项与内核配置的关系。

### systemd

systemd 管理现代 Linux 的服务、日志、设备事件和系统状态。仓库体量较大，学习时应先从 unit 文件和启动依赖入手，而不是直接修改核心源码。

推荐项目：为采集服务设计 socket activation、watchdog、restart policy、资源限制和 journald 日志策略，并验证异常退出恢复。

### BusyBox

BusyBox 将常用 Unix 工具合并为单个可执行文件，是许多精简 rootfs 的基础。这里列出的 GitHub 地址是镜像。

推荐项目：手动制作 initramfs，编译静态 BusyBox，编写 `/init`，在 QEMU 中启动到 shell，并挂载 proc、sysfs 和 devtmpfs。

### Bootlin Training Materials

Bootlin 的培训材料覆盖嵌入式 Linux、内核、驱动、Buildroot 和 Yocto，实验路线清晰，适合用作上述仓库的配套教材。

## 推荐实践路线

### 路线 A：MCU 与 RTOS

1. 裸机完成 GPIO、UART、timer、DMA 和中断。
2. 使用 FreeRTOS 理解 task、queue、通知和同步。
3. 选择 Zephyr 或 RT-Thread 完成设备驱动、shell、网络和文件系统。
4. 用 Unity/Ceedling 做主机侧单元测试，并加入 CI。
5. 完成一个含 bootloader、参数存储、看门狗和 OTA 的综合项目。

### 路线 B：嵌入式 Linux BSP

1. 用 QEMU 或开发板理解 U-Boot -> Kernel -> rootfs 启动链。
2. 用 Buildroot 生成最小系统，并能稳定复现配置。
3. 学习设备树、platform driver、中断、DMA 和字符设备。
4. 增加 systemd/BusyBox 服务、日志和应用程序。
5. 使用 LTP 做回归，再用 SWUpdate 完成 A/B 升级和回滚。

### 路线 C：量产型 Linux 产品

1. 使用 Yocto 建立产品 layer、BSP layer 和应用 layer。
2. 固化 SDK、license manifest、SBOM 和可复现构建流程。
3. 加入 secure boot、签名升级、只读文件系统和数据分区。
4. 建立硬件在环、LTP、启动时间、功耗和断电恢复测试。

## 做项目时应保留的成果

- 架构图、启动流程图和关键时序图。
- 可复现的构建配置、工具链版本和一键构建脚本。
- 驱动接口说明、设备树片段与测试方法。
- 单元测试、硬件在环测试、异常注入和覆盖率结果。
- 已定位问题的日志、根因、修复 commit 和回归结果。
- 对功耗、启动时间、内存占用、实时性或网络性能的量化数据。

---

## 面向具身智能嵌入式软件的简历改造建议

> 本节根据 `嵌入式软件.pdf` 的现有经历整理。原则是先重新表达已经完成的工作，再通过真实开发补齐 ROS 2、实时性和机器人执行链路；不要把计划中的功能直接写成已经完成。

### 当前能力与岗位的匹配关系

| 简历现有经历 | 对具身智能嵌软的价值 | 当前缺口 |
| --- | --- | --- |
| RFSoC/Zynq ARM+FPGA 异构开发 | 边缘计算、感知加速、高速数据面、软硬件协同 | 缺 ROS 2 接口、时间同步、端到端延迟与抖动数据 |
| 100G UDP、共享内存、乒乓缓冲 | 高频传感数据搬运、零拷贝思路、背压处理 | 缺丢包/乱序/阻塞故障注入和 P50/P99 指标 |
| PS 端 lwIP 控制链路 | MCU/SoC 控制面、网络命令与状态管理 | 缺 RTOS 任务设计、状态机、看门狗和故障恢复描述 |
| xv6 内核扩展 | 页表、调度、中断、锁与并发基础 | 缺 PREEMPT_RT、实时调度、驱动或实时性能实验 |
| C++ Reactor HTTP 服务 | Linux C++、并发、网络与工程能力 | 与机器人设备链路较远，AI Agent 表述也缺少模型部署细节 |
| Python/PyTorch 基础 | 可转向 Jetson/TensorRT 边缘推理 | 缺 ONNX/TensorRT、ROS 2 图像管线和性能数据 |

你的差异化优势应定位为：**懂 FPGA/SoC 数据面、Linux C++ 和实时系统基础的具身智能嵌入式候选人**，而不是泛化成“会一点 MCU、后端和 AI”。

### 简历中应立即修正的问题

1. 把求职方向从“嵌入式软件开发工程师”收窄为“具身智能嵌入式软件 / 机器人系统软件 / 边缘计算”。
2. `XIlinx` 改为 `Xilinx`，`zynq` 改为 `Zynq`，`axi` 改为 `AXI`，`udp` 改为 `UDP`，`pytorch` 改为 `PyTorch`。
3. 删除“熟悉 掌握”等重复文字，修复“Epoll 等。”附近的括号和句号错误。
4. “熟悉 C++11/17 语法标准”改成具体能力，例如 RAII、智能指针、并发、内存模型和性能分析；只保留实际掌握的内容。
5. “显著提高吞吐量”“保障实时性”等描述没有数据支撑，应替换为带测试条件的吞吐、延迟、抖动、丢包率和 CPU 占用。
6. 第一页信息过密、第二页大量留白。建议把每个项目压到 3-4 条高信息密度 bullet，并通过分页控制让项目完整落在同一页。
7. 实习经历只有一句“重构页面、数据库和后端逻辑”，需要补充技术栈、负责模块、问题、动作和结果；如果与目标岗位关系弱，可压缩为 1-2 条。
8. 当前“Cpp-AI应用 Http服务框架”的主体其实是 HTTP Server，AI 部分没有模型、推理框架或指标。应改名为“C++ 高并发网络服务框架”，或在完成真实边缘推理接入后再使用 AI 项目名。

### 项目在简历中的推荐顺序

1. RFSoC 异构实时感知数据通路。
2. 新增的 ROS 2 + micro-ROS 传感器/执行器网关项目。
3. RISC-V xv6 内核机制与并发优化。
4. C++ HTTP 服务框架缩减为 2 条，或者在版面不足时移除。

具身智能岗位更关心“传感器数据怎样可靠进入计算图、控制命令怎样确定性地下发到执行器”，因此新项目应覆盖完整链路，而不是再增加一个普通 Web 项目。

## 现有项目经历改写模板

### RFSoC 项目：建议标题

**RFSoC 异构实时感知数据通路 | Zynq UltraScale+、C/C++、Verilog、AXI、UDP**

建议把现有长段落收敛为以下形式：

- 面向低空目标感知与通信融合场景，设计 OFDM 实时处理链，将波形生成、同步、频偏校正、通信解调和回波预处理部署到 FPGA PL，并在 ARM PS 侧完成控制与状态管理。
- 通过 AXI HP/AXI DMA（按实际实现选择）连接 PS 与 PL，构建 100GbE UDP 高速数据链路；上位机使用共享内存和乒乓缓冲解耦接收、处理与可视化线程，处理连续数据流中的带宽差异与背压。
- 在 Zynq PS 侧基于 lwIP 实现 UDP 控制通道，完成参数配置、启停控制与运行状态交互；补充超时、非法命令和断链恢复机制后再写入简历。
- 在 `[数据帧大小]`、`[采样率/包速率]` 条件下达到 `[实测吞吐]`，端到端延迟 P50/P99 为 `[实测值]`，丢包率为 `[实测值]`，PL 资源占用为 `[实测值]`。

最后一条必须通过脚本和仪器真实测量。如果暂时没有数据，就写“建立吞吐、端到端延迟和丢包率测试方法”，不要填写猜测值。

### RFSoC 项目：最值得补做的三个增量

1. **ROS 2 数据出口**：用 `rclcpp` 把感知结果发布为自定义 message、`sensor_msgs/PointCloud2` 或目标列表；配置 QoS、时间戳和 frame_id。
2. **时间同步与可观测性**：记录 FPGA、PS 和上位机各阶段时间戳；条件允许时加入 PTP/硬件时间戳，输出 P50、P95、P99 延迟和 jitter。
3. **硬件在环回放**：保存原始数据并支持确定性回放，注入丢包、乱序、超时和处理阻塞，验证缓冲区水位、降级策略和恢复行为。

完成后可以把标题升级为“RFSoC + ROS 2 异构实时感知平台”，这会比单纯强调 OFDM 更贴近具身智能系统软件岗位。

### xv6 项目：建议标题

**RISC-V xv6 内核机制与并发优化 | C、RISC-V、虚拟内存、中断、锁**

- 扩展 xv6 系统调用与 trap 处理流程，实现 alarm 等内核功能，并跟踪用户态、内核态切换和上下文保存过程。
- 修改页表映射以优化用户空间与内核空间的数据访问路径，实现 `mmap` 文件映射并处理映射建立、缺页与资源回收。
- 分析物理页分配和 buffer cache 的锁竞争，调整数据结构与锁粒度；使用 `[测试方法]` 将 `[指标]` 从 `[原值]` 改善到 `[实测值]`。
- 基于上下文切换机制在用户态实现协程，说明协程栈、调度入口、保存寄存器和退出回收机制。

“正确使用锁很困难”不适合作为技术亮点，应改成具体冲突、采用的锁策略和验证结果。

### C++ HTTP 项目：建议处理方式

如果暂时保留，标题改成：

**C++ 高并发网络服务框架 | Reactor、epoll、OpenSSL、线程池**

- 基于 Reactor + epoll 实现 HTTP/HTTPS 服务，设计动态路由、中间件、会话管理和异常处理机制。
- 使用线程池、连接池和缓存优化并发请求处理，在 `[并发连接数]` 下达到 `[QPS]`，P99 延迟为 `[实测值]`；使用 GDB、perf 或 sanitizer 定位 `[真实问题]`。

删除“开发 AI 对话助手所以具备 AI 能力”的暗示。只有完成 ONNX/TensorRT 推理、模型量化、内存和延迟分析后，才把它作为边缘 AI 项目描述。

## 建议新增的主项目

### ROS 2 + micro-ROS 实时传感器与执行器网关

这是最适合补齐当前简历短板的项目。建议硬件使用 STM32/ESP32/Zephyr 开发板加 Linux PC、树莓派或 Jetson；有 CAN 电机和编码器更好，没有实物时可先用回环设备和仿真节点。

#### 最小可交付版本

- MCU 端使用 FreeRTOS 或 Zephyr，通过定时器触发、DMA 和中断采集 IMU/编码器，使用 micro-ROS XRCE-DDS 发布带硬件时间戳的数据。
- Linux 端实现 ROS 2 lifecycle node，配置 sensor data QoS，完成参数、诊断、超时检测和设备重连。
- 实现一个 `ros2_control` hardware interface，把位置/速度命令经 CAN/CAN-FD、UART 或 UDP 下发，并读取编码器与故障状态。
- 建立端到端测试：采样频率、命令周期、P50/P99 延迟、jitter、丢帧率、CPU 占用和断链恢复时间。
- 使用 rosbag2 或自建二进制日志回放数据，注入延迟、丢包、乱序、传感器冻结和执行器超时。

#### 简历模板（完成后使用）

**ROS 2 + micro-ROS 实时传感器/执行器网关 | C/C++、Zephyr/FreeRTOS、DDS、CAN-FD**

- 在 MCU 端基于 `[RTOS]` 实现 `[频率]` Hz IMU/编码器采集，采用 timer + DMA + ISR/task 解耦，使用 micro-ROS 发布硬件时间戳数据。
- 实现 ROS 2 lifecycle driver 与 `ros2_control` hardware interface，通过 `[总线]` 完成状态回读和控制指令下发，并实现超时保护、重连和故障状态机。
- 针对 DDS QoS、线程优先级和缓冲深度进行调优，在 `[负载条件]` 下实现 P99 延迟 `[实测值]`、jitter `[实测值]`、丢帧率 `[实测值]`。
- 建立 rosbag2 回放与故障注入测试，覆盖断链、数据冻结、乱序、执行器超时和进程重启场景。

### 可选增强：Jetson ROS 2 边缘感知管线

如果目标岗位强调感知部署，可在完成上面的实时网关后再做：

- 将 PyTorch 模型导出 ONNX，使用 TensorRT FP16/INT8 部署到 Jetson。
- 用 ROS 2 component/composable node 组织相机、预处理、推理和后处理节点。
- 使用 NVIDIA Isaac ROS 或自写 CUDA 节点，分析 host/device 拷贝和图像格式转换开销。
- 对比 PyTorch、ONNX Runtime、TensorRT 的 FPS、P50/P99 延迟、显存和功耗。
- 把推理结果送入 Nav2、MoveIt 2 或控制状态机，形成“感知结果真正驱动行为”的闭环。

## 具身智能嵌软 GitHub 项目推荐

> 热度数据同样为 2026-11-01 的近似快照。学习时不建议把整套仓库全部跑通，应围绕自己的传感器、执行器和性能目标选择子模块。

| 项目 | 对应能力 | 建议产出 | 热度 |
| --- | --- | --- | ---: |
| [ROS 2](https://github.com/ros2/ros2) | 机器人中间件、节点、QoS、生命周期 | C++ 传感器驱动与诊断节点 | ~6.3k stars |
| [ros2_control](https://github.com/ros-controls/ros2_control) | 执行器抽象与实时控制接口 | 自定义 hardware interface | ~1.1k |
| [micro-ROS setup](https://github.com/micro-ROS/micro_ros_setup) | MCU 与 ROS 2 通信 | MCU 传感器节点和 agent | ~527 |
| [micro-ROS Zephyr Module](https://github.com/micro-ROS/micro_ros_zephyr_module) | Zephyr + micro-ROS | Zephyr IMU/编码器发布节点 | ~93 |
| [Fast DDS](https://github.com/eProsima/Fast-DDS) | DDS、QoS、发现与传输 | QoS/吞吐/延迟对比实验 | ~2.9k |
| [Eclipse iceoryx](https://github.com/eclipse-iceoryx/iceoryx) | 进程间零拷贝 | 大带宽传感数据 IPC 基准 | ~2.2k |
| [ROS 2 realtime_support](https://github.com/ros2/realtime_support) | 实时延迟与 jitter 测量 | PREEMPT_RT 前后对比报告 | ~82 |
| [NVIDIA Isaac ROS Common](https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_common) | Jetson ROS 2 加速基础设施 | TensorRT 感知节点与基准测试 | ~322 |
| [jetson-inference](https://github.com/dusty-nv/jetson-inference) | Jetson/TensorRT 边缘推理 | ONNX/TensorRT 部署对比 | ~9.0k |
| [Navigation2](https://github.com/ros-navigation/navigation2) | 移动机器人导航 | 将感知/定位接入行为树 | ~5.0k |
| [MoveIt 2](https://github.com/moveit/moveit2) | 机械臂规划与执行 | ROS 2 控制链路联调 | ~2.1k |
| [PX4 Autopilot](https://github.com/PX4/PX4-Autopilot) | 实时飞控、传感器与 uORB | 阅读驱动、调度和故障保护 | ~13.0k |
| [ODrive](https://github.com/ODriveRobotics/ODrive) | 高性能电机控制 | 编码器、控制环与通信分析 | ~3.8k |
| [SimpleFOC](https://github.com/simplefoc/Arduino-FOC) | BLDC/步进电机 FOC 入门 | 电流/速度/位置闭环实验 | ~3.1k |
| [moteus](https://github.com/mjbots/moteus) | 机器人关节伺服 | CAN-FD 控制和故障状态机 | ~1.4k |
| [Unitree ROS 2](https://github.com/unitreerobotics/unitree_ros2) | 四足/人形机器人接口 | 读取状态、下发命令、DDS 联调 | ~879 |

### 推荐阅读顺序

1. **ROS 2 + Fast DDS**：先掌握 node、executor、callback group、QoS、lifecycle 和 tracing。
2. **micro-ROS + Zephyr/FreeRTOS**：打通 MCU 采集到 Linux 计算节点的数据链。
3. **ros2_control + moteus/ODrive/SimpleFOC**：理解执行器驱动、控制周期和故障保护。
4. **realtime_support + iceoryx**：测量实时性并优化大数据 IPC，避免只说“低延迟”。
5. **Isaac ROS/jetson-inference**：补齐边缘模型部署和 GPU 数据通路。
6. **Nav2/MoveIt 2/Unitree ROS 2**：把底层驱动接入完整机器人功能闭环。

## 8 周可执行补强计划

| 周次 | 任务 | 可验收成果 |
| --- | --- | --- |
| 1 | ROS 2 C++ node、topic/service、QoS、lifecycle | 一个可配置、可诊断的传感器模拟节点 |
| 2 | executor、callback group、rosbag2、tracing | 回放测试和回调延迟报告 |
| 3 | micro-ROS + MCU/Zephyr | IMU/编码器数据进入 ROS 2 |
| 4 | CAN/CAN-FD 或串口协议、状态机、重连 | 设备驱动和故障注入测试 |
| 5 | ros2_control hardware interface | 状态回读和周期控制闭环 |
| 6 | PREEMPT_RT、线程优先级、内存锁定 | P50/P99/jitter 对比数据 |
| 7 | iceoryx 或共享内存大数据通路 | 吞吐、拷贝次数和 CPU 占用报告 |
| 8 | Jetson/TensorRT 或 RFSoC ROS 2 桥接 | 演示视频、架构图、README 和简历量化 bullet |

## 投递前自检

- 项目是否有源码、README、架构图、运行方法和测试脚本。
- 是否能说明每个线程/进程的职责、优先级、通信方式和缓冲策略。
- 是否能给出端到端延迟、P99、jitter、丢帧率、CPU/内存占用，而不是只说“实时”。
- 是否测试过断链、超时、数据冻结、乱序、进程崩溃和设备重启。
- 是否能解释 ROS 2 QoS、DDS discovery、callback group 和 executor 对实时性的影响。
- 是否能解释 MCU 中 ISR、DMA、task 和 lock-free/ring buffer 的数据所有权。
- 是否只写真实完成的内容，并能在面试中现场展示日志、曲线或代码。

---

## RK35xx 嵌入式项目推荐

RK35xx 通常包括 RK3566、RK3568、RK3588/RK3588S 等平台。对具身智能嵌软岗位而言，最有价值的不是“成功烧录系统”，而是能展示 BSP、驱动、零拷贝多媒体、NPU 部署、实时通信和系统稳定性之间的完整工程链路。

### RK35xx 相关仓库

| 仓库 | 主要用途 | 建议关注内容 |
| --- | --- | --- |
| [rockchip-linux/kernel](https://github.com/rockchip-linux/kernel) | Rockchip BSP Kernel | RK35xx DTS、时钟、pinctrl、PCIe、V4L2、RGA、NPU 相关驱动；先确认目标板对应分支 |
| [rockchip-linux/u-boot](https://github.com/rockchip-linux/u-boot) | Rockchip U-Boot | SPL/TPL、启动介质、环境变量、FIT、设备树与内核启动参数 |
| [rockchip-linux/rkbin](https://github.com/rockchip-linux/rkbin) | DDR、BL31、loader 等二进制固件 | 理解启动镜像组成和打包流程；该仓库主要是预编译固件，不是可完整审计的源码项目 |
| [rockchip-linux/mpp](https://github.com/rockchip-linux/mpp) | Rockchip Media Process Platform | VPU 硬件编解码、buffer group、码流和图像帧管理 |
| [rockchip-linux/rga](https://github.com/rockchip-linux/rga) | 2D 图像加速 | resize、crop、颜色转换、旋转及 DMA-BUF 数据通路 |
| [airockchip/rknn-toolkit2](https://github.com/airockchip/rknn-toolkit2) | RKNN 模型转换与部署工具 | ONNX -> RKNN、量化、精度分析和 runtime API |
| [airockchip/rknn_model_zoo](https://github.com/airockchip/rknn_model_zoo) | RKNN 模型示例 | 分类、检测、分割模型在 RK356x/RK3588 上的预处理、推理和后处理 |
| [Joshua-Riek/ubuntu-rockchip](https://github.com/Joshua-Riek/ubuntu-rockchip) | RK35xx Ubuntu 社区镜像 | 桌面/服务器镜像构建、板级适配和常见外设支持 |
| [Armbian Build Framework](https://github.com/armbian/build) | 多板卡 Linux 镜像构建 | patch 分层、board family、kernel config、rootfs 和发行版集成 |
| [Orange Pi Build](https://github.com/orangepi-xunlong/orangepi-build) | Orange Pi BSP 构建 | Orange Pi 5 等 RK3588 板卡镜像和内核构建；注意厂商分支差异 |
| [Radxa Rockchip BSP](https://github.com/radxa-build/rockchip-bsp) | Radxa Rockchip 构建元数据 | Radxa RK35xx 板卡 BSP、包和镜像组织方式 |
| [FFmpeg Rockchip](https://github.com/nyanmisaka/ffmpeg-rockchip) | FFmpeg 硬件编解码集成 | MPP、RGA、DRM PRIME/DMA-BUF 和硬件转码流水线 |

> 使用这些仓库前必须核对板卡型号、SoC、内存配置、内核版本和默认分支。同一块 RK3588 板卡的 vendor 5.10、vendor 6.1 与 mainline kernel 的驱动完整度可能明显不同，不能直接混用补丁和设备树。

### 项目一：RK3588 ROS 2 多路视觉与 NPU 推理节点

该项目最适合与简历中的 RFSoC 高速数据链路结合，能够证明你不仅会运行模型，还能处理摄像头、内存、NPU 和 ROS 2 之间的数据搬运与性能问题。

#### 建议架构

```text
MIPI CSI/USB Camera
        |
   V4L2/libcamera
        |
 DMA-BUF/DRM PRIME
        |
 RGA resize/颜色转换
        |
 RKNN NPU inference
        |
 ROS 2 Detection/Segmentation message
        |
 rosbag2 / Nav2 / 控制状态机
```

#### 必做内容

- 使用 V4L2 或 libcamera 获取摄像头帧，明确像素格式、stride、时间戳和 buffer 生命周期。
- 使用 RGA 完成 resize、crop 和 NV12/RGB 转换，对比 CPU/OpenCV 与 RGA 的延迟和 CPU 占用。
- 将 ONNX 模型转换成 RKNN，完成 FP16/INT8 量化、精度对比和 RKNN runtime 推理。
- 尽量使用 DMA-BUF/DRM PRIME 传递图像，记录每个阶段是否发生内存拷贝；不能仅凭 API 名称宣称“零拷贝”。
- 封装 ROS 2 component/lifecycle node，配置 sensor data QoS、诊断、掉线重连和帧超时。
- 测量单路和多路输入下的 FPS、P50/P99 延迟、jitter、CPU/NPU/内存占用、温度、功耗和降频情况。

#### 简历模板（完成后使用）

**RK3588 多路视觉 NPU 推理与 ROS 2 数据管线 | C++、V4L2、RGA、RKNN、DMA-BUF**

- 在 RK3588 上构建 V4L2 -> RGA -> RKNN -> ROS 2 视觉管线，完成 `[模型]` 的 INT8 量化与 NPU 部署，并发布 `[消息类型]` 感知结果。
- 基于 DMA-BUF/DRM PRIME 管理摄像头和加速器 buffer，减少 `[阶段]` 的数据拷贝；相较 OpenCV CPU 预处理，将 `[分辨率]` 图像预处理耗时由 `[原值]` 降至 `[实测值]`。
- 在 `[路数/分辨率/帧率]` 条件下达到 `[FPS]`，端到端 P99 延迟 `[实测值]`，CPU 占用 `[实测值]`，连续运行 `[时长]` 无内存增长或帧阻塞。
- 实现摄像头断连、NPU 超时、队列积压和温度降频监测，通过 ROS 2 diagnostics 输出状态并完成自动恢复。

### 项目二：RK3568 机器人底盘/工业控制网关

RK3568 的网口、CAN、UART、RS485、SPI 和 GPIO 资源适合做机器人底层控制网关。项目重点应放在确定性通信、设备管理和异常恢复，而不是 UI。

#### 建议内容

- 使用 Buildroot 或 Yocto 构建最小系统，固化 U-Boot、kernel、rootfs、设备树和应用版本。
- 通过 SocketCAN/CAN-FD 连接电机驱动器，通过 RS485/Modbus 连接传感器，使用 epoll/timerfd/eventfd 组织事件循环。
- 实现 ROS 2 或自定义共享内存网关，将上层速度/位置命令转换为底层总线帧，并发布编码器、电流、温度和故障状态。
- 设计通信状态机：启动自检、使能、运行、降级、急停、故障锁存和恢复。
- 加入硬件看门狗、systemd watchdog、只读 rootfs、日志限额和 SWUpdate A/B 升级。
- 测量控制周期 jitter、总线利用率、命令超时反应时间、进程重启时间和断电升级恢复结果。

#### 简历模板（完成后使用）

**RK3568 机器人实时控制网关 | Linux、C++、SocketCAN、RS485、ROS 2**

- 基于 Buildroot/Yocto 构建 RK3568 最小 Linux 系统，完成 U-Boot、kernel、DTS、rootfs 和应用的一体化版本管理。
- 使用 epoll + timerfd 实现 `[周期]` 控制循环，通过 CAN-FD/RS485 完成 `[设备数量]` 个执行器与传感器的数据采集和命令下发。
- 设计设备状态机、命令超时、急停、总线恢复和看门狗机制，在故障注入测试中将异常检测与安全停机时间控制在 `[实测值]`。
- 建立 A/B 升级和自动回滚流程，覆盖升级断电、镜像校验失败和应用健康检查失败场景。

### 项目三：RK3588 硬件编解码与共享内存视频服务

这个方向适合强化 C++、Linux 多媒体和高速数据处理能力，也能与现有 HTTP/网络项目结合。

- 使用 MPP 完成 H.264/H.265 硬件解码或编码，使用 RGA 做格式转换和缩放。
- 通过 DRM PRIME/DMA-BUF 在解码、RGA、显示或推理模块之间传递帧。
- 设计有界队列和丢帧策略，区分实时流与完整录像的背压要求。
- 使用 FFmpeg Rockchip、GStreamer 或自写 MPP 应用对比吞吐、延迟、CPU 占用和内存带宽。
- 增加 RTSP/WebRTC/ROS 2 输出时，记录网络抖动、编码缓冲和端到端玻璃到玻璃延迟。

### 项目四：RK35xx BSP Bring-up 与板级稳定性

如果有自研板或外设扩展板，可做更偏 BSP/驱动的项目：

- 分析 MaskROM -> loader/SPL -> BL31 -> U-Boot -> kernel -> init 的完整启动链。
- 移植 eMMC/SD、GMAC、PCIe、USB、MIPI CSI、HDMI、Wi-Fi/BT 中至少两类外设。
- 修改 DTS 中的 clock、reset、regulator、pinctrl、IOMMU 和 reserved-memory，并解释每项与驱动 probe 的关系。
- 使用 ftrace、trace-cmd、perf、devlink、ethtool、v4l2-ctl 等工具定位启动或运行异常。
- 完成 24/48 小时压力测试、反复重启、掉电、温升和 suspend/resume 测试，整理问题和修复记录。

## Linux 驱动项目与仓库

### 推荐仓库

| 仓库 | 用途 | 使用建议 |
| --- | --- | --- |
| [Linux Kernel](https://github.com/torvalds/linux) | 主线内核与正式驱动 | 重点阅读 `Documentation/driver-api`、`drivers/iio`、`drivers/media`、`drivers/net/can` 和同类设备驱动 |
| [Rockchip BSP Kernel](https://github.com/rockchip-linux/kernel) | RK35xx 厂商驱动 | 用于板卡现有功能和 vendor patch；同时与 mainline 对照，避免只会复制厂商代码 |
| [Linux Kernel Module Programming Guide](https://github.com/sysprog21/lkmpg) | 内核模块入门 | 学习当前内核模块、proc/sysfs、并发和调试基础 |
| [Linux Kernel Module Cheat](https://github.com/cirosantilli/linux-kernel-module-cheat) | QEMU 可运行内核实验 | 适合可复现地实验模块、设备树、调试和内核机制 |
| [LDD3 Examples](https://github.com/martinezjavier/ldd3) | 《Linux Device Drivers 3》示例 | 只学习思想，API 针对旧内核，不能原样用于 5.x/6.x 项目 |
| [Bootlin Training Materials](https://github.com/bootlin/training-materials) | 内核与驱动实验 | 配合开发板或 QEMU 系统学习 platform、I2C、SPI、设备树和调试 |
| [Analog Devices Linux](https://github.com/analogdevicesinc/linux) | 大量工业传感器/IIO 驱动 | 学习 regmap、IIO channel、trigger、buffer 和时间戳的真实实现 |
| [Linux CAN Utilities](https://github.com/linux-can/can-utils) | SocketCAN 工具与示例 | 验证 CAN/CAN-FD 驱动、过滤、错误帧、bus-off 和性能 |
| [libcamera](https://github.com/libcamera-org/libcamera) | Linux 摄像头用户态框架 | 结合 V4L2 subdev、media controller、buffer 和相机 pipeline 学习 |

### 驱动学习路线

#### 1. 字符设备与并发基础

实现一个虚拟/环形缓冲字符设备，支持：

- `open/read/write/release`、阻塞和非阻塞访问。
- wait queue、`poll/epoll`、`ioctl` 和 mmap（仅在确有共享内存需求时使用）。
- mutex、spinlock、atomic 和 kfifo，并解释每种同步原语的上下文限制。
- KUnit 或用户态压力测试，覆盖多进程并发、信号中断、设备删除和错误路径。

不要把最简单的 hello module 当成项目经历；它只能作为第一天练习。

#### 2. Device Tree + platform driver

实现一个板级 GPIO/中断设备或自定义 FPGA IP 驱动：

- 使用 `of_match_table`、platform resource、devm API 和 IRQ。
- 解析 `reg`、`interrupts`、`clocks`、`resets`、`pinctrl` 和 `*-supply`。
- 实现 runtime PM、suspend/resume 和设备卸载路径。
- 使用 debugfs、ftrace 和 dynamic debug 定位问题；不要用无约束 printk 代替调试设计。

#### 3. I2C/SPI 传感器 IIO 驱动

推荐选择 IMU、ADC、磁力计或温度传感器，按内核 IIO 框架实现：

- regmap、芯片 ID 和初始化寄存器。
- `read_raw`、scale、sampling frequency 等 channel 属性。
- data-ready IRQ、triggered buffer 和内核时间戳。
- 校准、量程、ODR 配置和错误恢复。
- 使用 `iio_info`、`iio_readdev` 或自写应用进行采样率、丢样和时间戳测试。

这是具身智能最值得做的驱动项目，因为 IMU、编码器和 ADC 数据质量直接影响状态估计与控制。

#### 4. V4L2 Camera Sensor/Sub-device

在有 MIPI CSI 摄像头和原理图资料的前提下：

- 实现 sensor subdev、media bus format、controls、stream on/off 和 runtime PM。
- 配置 clock、regulator、GPIO reset/pwdn 和 endpoint graph。
- 使用 media-ctl、v4l2-ctl 和 yavta 验证格式、帧率、buffer 和掉帧。
- 分析传感器时间戳与系统时钟关系，避免只验证“能出图”。

#### 5. DMA-BUF/零拷贝数据通路

适合结合 RK3588 V4L2、RGA、MPP 和 RKNN：

- 理解 exporter/importer、attachment、sg_table、cache coherency 和 fence。
- 用 trace 或性能计数证明拷贝次数，检查 CPU cache 同步和 IOMMU 映射。
- 对比 memcpy、普通 mmap 和 DMA-BUF 路径的延迟、CPU 占用和内存带宽。

#### 6. SocketCAN 与机器人总线

- 先使用 can-utils 构造正常帧、错误帧、高负载和 bus-off 场景。
- 若硬件控制器已有驱动，优先做 transceiver、设备树、时钟和错误恢复调试；不要为了“写驱动”重复实现已有成熟控制器驱动。
- 用户态实现带序号、时间戳、超时和状态机的执行器协议，统计控制周期 jitter 与错误恢复时间。

### Linux 驱动简历模板（完成后使用）

**RK3568 I2C IMU IIO 驱动与实时采集 | Linux 6.1、Device Tree、I2C、IRQ、IIO**

- 基于 Linux IIO 框架实现 `[IMU 型号]` 驱动，使用 regmap 完成寄存器访问，支持量程、ODR、scale、采样频率和校准参数配置。
- 通过 data-ready IRQ + triggered buffer 采集六轴数据并添加内核时间戳，在 `[ODR]` 下连续运行 `[时长]`，丢样率 `[实测值]`、时间戳 jitter `[实测值]`。
- 完成 DTS 中 I2C、IRQ、pinctrl、regulator 和 clock 配置，实现 runtime PM、suspend/resume 与设备异常重初始化。
- 使用 dynamic debug、ftrace 和 i2c-tools 定位 `[真实问题]`，增加并发读取、拔插/复位和错误注入测试。

### 项目优先级建议

结合你现有简历，推荐按以下顺序补充：

1. **RK3588 ROS 2 + RKNN 视觉管线**：复用现有 FPGA/高速数据和 PyTorch 基础，最快形成差异化。
2. **RK3568 IIO IMU 驱动**：补齐 Linux 驱动、设备树、中断、时间戳和传感器工程能力。
3. **ROS 2 + CAN-FD 执行器网关**：形成从感知到控制的闭环。
4. **Buildroot/Yocto + U-Boot + A/B 升级**：补齐量产 BSP 和系统工程能力。
5. 最后再深入 V4L2 sensor 或 DMA-BUF，因为这两项需要更完整硬件资料和较长调试周期。

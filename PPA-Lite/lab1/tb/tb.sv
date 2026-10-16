// ===================================================================================================
// 文件名称: tb.sv
// 模块名称: tb (Testbench 顶层)
// 功能描述: PPA-Lite Lab1 的 SystemVerilog 顶层仿真环境。
//
// 本文件功能:
//   1. 实例化 M1 (apb_slave_if) 和 M2 (packet_sram)，并完成连线
//   2. 生成仿真时钟 (PCLK, 周期 10ns) 和复位序列 (PRESETn 低有效, 初始持续 5 拍)
//   3. 驱动 M3 占位信号 (Lab1 中 M3 未实现, 由 TB 直接赋值模拟)
//   4. 提供复用 APB 驱动任务: apb_write / apb_read (两段式时序)
//   5. 提供绿比对照辅助任务: check_eq (自动 PASS/FAIL 打印并统计计数)
//   6. main initial 块: 等待复位结束后调用各阶段3测试用例 (占位区)
//   7. 仿真结束时打印汇总并保存 result_summary.txt
//
// APB 任务时序说明 (以 apb_write 为例):
//   - Cycle N  : @(posedge PCLK)+#1 → 驱动 PSEL=1,PENABLE=0,PWRITE=1 (SETUP)
//   - Cycle N+1: @(posedge PCLK)+#1 → 驱动 PENABLE=1 (ACCESS)
//   - Cycle N+2: @(posedge PCLK)+#1 → DUT 已在 N+1 的上升沿采样并写入,
//                              此时采样 PSLVERR, 释放总线

// ===================================================================================================

`timescale 1ns/1ps

module tb;

  // ===================================================================================================
  // 第1节: 信号声明
  // ===================================================================================================

  // ---- 时钟与复位 ----
  logic        PCLK;      // APB 时钟, 10ns 周期 (100MHz)
  logic        PRESETn;   // APB 复位, 低有效; 初始拉低 5 个时钟后释放

  // ---- APB 总线信号 (连接到 M1 apb_slave_if) ----
  logic        PSEL;      // 从机选择
  logic        PENABLE;   // 传输使能 (ACCESS 阶段为 1)
  logic        PWRITE;    // 方向 (1=写, 0=读)
  logic [11:0] PADDR;     // 12-bit 地址
  logic [31:0] PWDATA;    // 写数据
  logic [31:0] PRDATA;    // 读数据 (来自 M1 组合输出)
  logic        PREADY;    // 固定 1 (M1 无等待态)
  logic        PSLVERR;   // 错误响应 (1=访问非法)

  // ---- M1 CSR 字段输出 (观察信号, 用于验收波形) ----
  logic        enable_o;         // CTRL.enable
  logic        start_o;          // CTRL.start (W1P 单拍脉冲)
  logic        algo_mode_o;      // CFG.algo_mode
  logic [3:0]  type_mask_o;      // CFG.type_mask
  logic [5:0]  exp_pkt_len_o;    // PKT_LEN_EXP.exp_pkt_len
  logic        done_irq_en_o;    // IRQ_EN.done_irq_en
  logic        err_irq_en_o;     // IRQ_EN.err_irq_en
  logic        irq_o;            // 中断输出 (= done_irq | err_irq)

    // ---- M1->M2 SRAM 写端口 (M1 输出, 连接到 M2 输入) ----
  logic        pkt_mem_we_o;      // SRAM 写使能
  logic [2:0]  pkt_mem_addr_o;    // SRAM 写地址 (0~7)
  logic [31:0] pkt_mem_wdata_o;   // SRAM 写数据

  // ---- M1->M2 SRAM 读端口1 (v1.02 新增, APB 读 PKT_MEM 路径) ----
  logic        pkt_mem_rd_en_o;   // M2 读使能1 (SETUP阶段提前发出)
  logic [2:0]  pkt_mem_rd_addr_o; // M2 读地址1 (PADDR[4:2])
  logic [31:0] pkt_mem_rd_data_i; // M2 读数据 (1拍延迟, 送回 M1 PRDATA)

  // ---- M3 占位信号 (Lab1 由 TB 直接驱动, 模拟 M3 输入到 M1) ----
  // 注: Lab1 阶段 M3 (packet_proc_core) 尚未实现,
  //      以下信号在各测试用例中按需赋值, 用于验证 M1 的 RES_* / STATUS 读通路
  logic        busy_i;            // M3 处理中标志 (= 0: M3 空闲, = 1: M3 繁忙)
  logic        done_i;            // M3 处理完成标志 (电平信号)
  logic        format_ok_i;       // M3 格式合法标志
  logic        length_error_i;    // M3 包长错误
  logic        type_error_i;      // M3 类型错误
  logic        chk_error_i;       // M3 头校验错误
  logic [5:0]  res_pkt_len_i;     // M3 解析包长 (注入到 RES_PKT_LEN)
  logic [7:0]  res_pkt_type_i;    // M3 解析包类型 (注入到 RES_PKT_TYPE)
  logic [7:0]  res_payload_sum_i; // M3 payload 字节和 (注入到 RES_PAYLOAD_SUM)
  logic [7:0]  res_payload_xor_i; // M3 payload XOR (注入到 RES_PAYLOAD_XOR)

  // ---- M2 读端口0占位 (Lab1 中 M3 未连接, TB 用占位信号防止 X 态) ----
  logic        m2_rd_en;          // M2 读使能0 (M3 未连接, 拉低即可)
  logic [2:0]  m2_rd_addr;        // M2 读地址0 (M3 未连接, 保持 0)
  logic [31:0] m2_rd_data;       // M2 读数据0 (M3 输出, Lab1 不检查)

  // ---- 测试统计计数器 ----
  integer pass_count; // PASS 用例计数
  integer fail_count; // FAIL 用例计数


  

endmodule

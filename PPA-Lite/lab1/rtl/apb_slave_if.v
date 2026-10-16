`timescale 1ns/1ps

module apb_slave_if (

  // ===========================================================================
  // APB 时钟与复位
  // ===========================================================================
  input  wire      PCLK,       // APB 时钟
  input  wire      PRESETn,    // APB 复位, 低有效 (异步复位)

  // ===========================================================================
  // APB 从机总线接口 (来自 APB Master / ppa_top)
  // ===========================================================================
  input  wire      PSEL,       // 从机选择: =1 表示本模块被选中
  input  wire      PENABLE,    // 传输使能: =1 表示进入 ACCESS 阶段
  input  wire      PWRITE,     // 方向: 1=写, 0=读
  input  wire [11:0] PADDR,    // 12-bit 地址 (对应 §4.2 地址空间)
  input  wire [31:0] PWDATA,   // 写数据 (APB Master 提供)
  output reg  [31:0] PRDATA,   // 读数据 (本模块组合输出, ACCESS 拍有效)
  output wire      PREADY,     // 就绪信号: 固定为 1 (本模块无等待态)
  output wire      PSLVERR,    // 错误响应: 访问非法时置 1 (§8.3)

  // ===========================================================================
  // CSR 字段输出 (组合输出, 送 M3 packet_proc_core)
  // ===========================================================================
  output wire      enable_o,   // CTRL[0]: 全局使能
  output reg       start_o,    // CTRL[1]: W1P 单拍脉冲 (触发 M3 处理)
  output wire      algo_mode_o,// CFG[0]: 算法模式 (1=执行hdr_chk校验)
  output wire [3:0] type_mask_o,// CFG[7:4]: 允许的包类型掩码
  output wire [5:0] exp_pkt_len_o,// PKT_LEN_EXP[5:0]: 软件声明的预期包长
  output wire      done_irq_en_o,// IRQ_EN[0]: 完成中断使能
  output wire      err_irq_en_o,// IRQ_EN[1]: 错误中断使能

  // ===========================================================================
  // SRAM 写端口 (组合输出, 直接驱动 M2 packet_sram 写端口)
  // ===========================================================================
  output wire      pkt_mem_we_o,    // M2 写使能 (APB写PKT_MEM区 且 busy=0 时有效)
  output wire [2:0] pkt_mem_addr_o, // M2 写地址 (PADDR[4:2], 范围 0-7)
  output wire [31:0] pkt_mem_wdata_o,// M2 写数据 (直接来自 PWDATA)

  // v1.02 新增: M2 读端口1 (APB 读 PKT_MEM 路径)
  output wire      pkt_mem_rd_en_o,    // M2 读使能 (APB读PKT_MEM区时有效, 送读端口1)
  output wire [2:0] pkt_mem_rd_addr_o, // M2 读地址 (PADDR[4:2], 送读端口1)
  input  wire [31:0] pkt_mem_rd_data_i, // M2 读数据 (来自读端口1, 1拍延迟, 透传至PRDATA)

  // ===========================================================================
  // M3 状态输入 (来自 packet_proc_core, 用于 STATUS/RES_*/ERR_FLAG 寄存器)
  // ===========================================================================
  input  wire      busy_i,       // M3 处理中标志 (影响 start 接受 & PKT_MEM 写保护)
  input  wire      done_i,       // M3 处理完成标志 (电平, DONE 态保持)
  input  wire      format_ok_i,  // M3 格式全通过标志
  input  wire      length_error_i,// M3 包长越界错误
  input  wire      type_error_i, // M3 包类型非法错误
  input  wire      chk_error_i,  // M3 头校验错误 (仅 algo_mode=1 时有效)
  input  wire [5:0] res_pkt_len_i, // M3 解析出的包长 (→ RES_PKT_LEN 寄存器)
  input  wire [7:0] res_pkt_type_i, // M3 解析出的包类型 (→ RES_PKT_TYPE 寄存器)
  input  wire [7:0] res_payload_sum_i, // M3 payload 字节和 (→ RES_PAYLOAD_SUM 寄存器)
  input  wire [7:0] res_payload_xor_i, // M3 payload 全字节 XOR (→ RES_PAYLOAD_XOR 寄存器)

  // ===========================================================================
  // 中断输出
  // ===========================================================================
  output wire      irq_o       // 中断输出: = done_irq | err_irq (组合逻辑)
);

// ===========================================================================
// 第1节: APB 地址常量定义
// ===========================================================================
//   对应规格 §5.2 完整寄存器表的偏移地址
// ===========================================================================
localparam [11:0] ADDR_CTRL          = 12'h000;  // CTRL: 全局控制
localparam [11:0] ADDR_CFG           = 12'h004;  // CFG: 算法配置
localparam [11:0] ADDR_STATUS        = 12'h008;  // STATUS: 运行状态 (RO)
localparam [11:0] ADDR_IRQ_EN        = 12'h00C;  // IRQ_EN: 中断使能 (RW)
localparam [11:0] ADDR_PKT_STA       = 12'h010;  // IRQ_STA: 中断使能 (RW1C)
localparam [11:0] ADDR_PKT_LEN_EXP   = 12'h014;  // PKT_LEN_EXP: 期望包长 (RW)
localparam [11:0] ADDR_RES_PKT_LEN   = 12'h018;  // RES_PKT_LEN: 解析包长结果 (RO)
localparam [11:0] ADDR_RES_PKT_TYPE  = 12'h01C;  // RES_PKT_TYPE: 解析包类型结果 (RO)
localparam [11:0] ADDR_RES_PLD_SUM   = 12'h020;  // RES_PAYLOAD_SUM: payload字节和 (RO)



endmodule
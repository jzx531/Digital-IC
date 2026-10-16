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
localparam [11:0] ADDR_IRQ_STA       = 12'h010;  // IRQ_STA: 中断状态 (RW1C)
localparam [11:0] ADDR_PKT_LEN_EXP   = 12'h014;  // PKT_LEN_EXP: 期望包长 (RW)
localparam [11:0] ADDR_RES_PKT_LEN   = 12'h018;  // RES_PKT_LEN: 解析包长结果 (RO)
localparam [11:0] ADDR_RES_PKT_TYPE  = 12'h01C;  // RES_PKT_TYPE: 解析包类型结果 (RO)
localparam [11:0] ADDR_RES_PLD_SUM   = 12'h020;  // RES_PAYLOAD_SUM: payload字节和 (RO)
localparam [11:0] ADDR_RES_PLD_XOR   = 12'h024;  // RES_PAYLOAD_XOR: payload异或 (RO)
localparam [11:0] ADDR_ERR_FLAG      = 12'h028;  // ERR_FLAG: 错误标志 (RO)
localparam [11:0] ADDR_PKT_MEM_BASE  = 12'h040;  // PKT_MEM Word 0
localparam [11:0] ADDR_PKT_MEM_LAST  = 12'h05C;  // PKT_MEM Word 7


// ===========================================================================
// 第2节: APB 访问阶段与地址合法性译码
// ===========================================================================
wire apb_setup;
wire apb_access;
wire apb_write;
wire apb_read;

wire pkt_mem_addr_valid;
wire csr_read_addr_valid;
wire csr_write_addr_valid;
wire read_addr_valid;
wire write_addr_valid;

assign apb_setup  = PSEL && !PENABLE;
assign apb_access = PSEL &&  PENABLE;
assign apb_write  = apb_access &&  PWRITE;
assign apb_read   = apb_access && !PWRITE;

// PKT_MEM 仅接受 0x040~0x05C 范围内的 32-bit 对齐地址。
assign pkt_mem_addr_valid = (PADDR >= ADDR_PKT_MEM_BASE) &&
                            (PADDR <= ADDR_PKT_MEM_LAST) &&
                            (PADDR[1:0] == 2'b00); //四字节对齐

// 所有已定义 CSR 均允许读取，包括 RO/W1P/RW1C 字段。
assign csr_read_addr_valid = (PADDR == ADDR_CTRL)         ||
                             (PADDR == ADDR_CFG)          ||
                             (PADDR == ADDR_STATUS)       ||
                             (PADDR == ADDR_IRQ_EN)       ||
                             (PADDR == ADDR_IRQ_STA)      ||
                             (PADDR == ADDR_PKT_LEN_EXP)  ||
                             (PADDR == ADDR_RES_PKT_LEN)  ||
                             (PADDR == ADDR_RES_PKT_TYPE) ||
                             (PADDR == ADDR_RES_PLD_SUM)  ||
                             (PADDR == ADDR_RES_PLD_XOR)  ||
                             (PADDR == ADDR_ERR_FLAG);

// CTRL.start 是合法的 W1P 字段；只拒绝 RO、保留和未定义 CSR 写入。
assign csr_write_addr_valid = (PADDR == ADDR_CTRL)       ||
                              (PADDR == ADDR_CFG)        ||
                              (PADDR == ADDR_IRQ_EN)     ||
                              (PADDR == ADDR_IRQ_STA)    ||
                              (PADDR == ADDR_PKT_LEN_EXP);

assign read_addr_valid  = csr_read_addr_valid || pkt_mem_addr_valid;
assign write_addr_valid = csr_write_addr_valid ||
                          (pkt_mem_addr_valid && !busy_i);

assign PREADY  = 1'b1;
assign PSLVERR = apb_access &&
                 (PWRITE ? !write_addr_valid : !read_addr_valid);


// ===========================================================================
// 第3节: CSR 存储字段与状态信号
// ===========================================================================
reg       enable_reg;
reg       algo_mode_reg;
reg [3:0] type_mask_reg;
reg [5:0] exp_pkt_len_reg;
reg       done_irq_en_reg;
reg       err_irq_en_reg;
reg       done_irq_reg;
reg       err_irq_reg;
reg       done_i_d;

wire error_any;
wire done_rise;

assign error_any = length_error_i || type_error_i || chk_error_i;
assign done_rise = done_i && !done_i_d;

assign enable_o       = enable_reg;
assign algo_mode_o    = algo_mode_reg;
assign type_mask_o    = type_mask_reg;
assign exp_pkt_len_o  = exp_pkt_len_reg;
assign done_irq_en_o  = done_irq_en_reg;
assign err_irq_en_o   = err_irq_en_reg;
assign irq_o          = done_irq_reg || err_irq_reg;


// ===========================================================================
// 第4节: PKT_MEM 读写接口
// ===========================================================================
// 写操作在 APB ACCESS 阶段生效；busy=1 时写使能保持为 0，且 PSLVERR=1。
assign pkt_mem_we_o       = apb_write && pkt_mem_addr_valid && !busy_i;
assign pkt_mem_addr_o     = PADDR[4:2];
assign pkt_mem_wdata_o    = PWDATA;

// M2 为同步读。SETUP 拍发请求，SETUP->ACCESS 上升沿由 M2 锁存数据，
// 随后的 ACCESS 拍即可通过 PRDATA 返回而无需插入等待态。
assign pkt_mem_rd_en_o   = apb_setup && !PWRITE && pkt_mem_addr_valid;
assign pkt_mem_rd_addr_o = PADDR[4:2];


// ===========================================================================
// 第5节: CSR 写、W1P 与中断状态时序逻辑
// ===========================================================================
always @(posedge PCLK or negedge PRESETn) begin
  if (!PRESETn) begin
    enable_reg      <= 1'b0;
    algo_mode_reg   <= 1'b1;
    type_mask_reg   <= 4'b1111;
    exp_pkt_len_reg <= 6'b0;
    done_irq_en_reg <= 1'b0;
    err_irq_en_reg  <= 1'b0;
    done_irq_reg    <= 1'b0;
    err_irq_reg     <= 1'b0;
    done_i_d        <= 1'b0;
    start_o         <= 1'b0;
  end else begin
    done_i_d <= done_i;

    // W1P 默认每拍清零，仅在一次合法 CTRL 写传输中拉高一拍。
    start_o <= 1'b0;

    if (apb_write) begin
      case (PADDR)
        ADDR_CTRL: begin
          enable_reg <= PWDATA[0];

          // CTRL 是整体写入。软件触发 start 时应同时写 enable=1，
          // 与规格附录中的 32'h0000_0003 访问序列保持一致。
          if (PWDATA[1] && PWDATA[0] && !busy_i)
            start_o <= 1'b1;
        end

        ADDR_CFG: begin
          algo_mode_reg <= PWDATA[0];
          type_mask_reg <= PWDATA[7:4];
        end

        ADDR_IRQ_EN: begin
          done_irq_en_reg <= PWDATA[0];
          err_irq_en_reg  <= PWDATA[1];
        end

        ADDR_IRQ_STA: begin
          // RW1C: 写 1 清零，写 0 保持。
          if (PWDATA[0])
            done_irq_reg <= 1'b0;
          if (PWDATA[1])
            err_irq_reg <= 1'b0;
        end

        ADDR_PKT_LEN_EXP: begin
          exp_pkt_len_reg <= PWDATA[5:0];
        end

        default: begin
          // RO、PKT_MEM 与非法地址在本时序块中均无 CSR 副作用。
        end
      endcase
    end

    // 新完成事件优先于同拍的软件 RW1C，避免丢失中断。
    if (done_rise && done_irq_en_reg)
      done_irq_reg <= 1'b1;

    if (done_rise && error_any && err_irq_en_reg)
      err_irq_reg <= 1'b1;
  end
end


// ===========================================================================
// 第6节: APB 读数据组合逻辑
// ===========================================================================
always @(*) begin
  PRDATA = 32'h0000_0000;

  if (apb_read) begin
    case (PADDR)
      ADDR_CTRL: begin
        // start 为 W1P，始终读回 0。
        PRDATA[0] = enable_reg;
      end

      ADDR_CFG: begin
        PRDATA[0]   = algo_mode_reg;
        PRDATA[7:4] = type_mask_reg;
      end

      ADDR_STATUS: begin
        PRDATA[0] = busy_i;
        PRDATA[1] = done_i;
        PRDATA[2] = error_any;
        PRDATA[3] = format_ok_i;
      end

      ADDR_IRQ_EN: begin
        PRDATA[0] = done_irq_en_reg;
        PRDATA[1] = err_irq_en_reg;
      end

      ADDR_IRQ_STA: begin
        PRDATA[0] = done_irq_reg;
        PRDATA[1] = err_irq_reg;
      end

      ADDR_PKT_LEN_EXP: begin
        PRDATA[5:0] = exp_pkt_len_reg;
      end

      ADDR_RES_PKT_LEN: begin
        PRDATA[5:0] = res_pkt_len_i;
      end

      ADDR_RES_PKT_TYPE: begin
        PRDATA[7:0] = res_pkt_type_i;
      end

      ADDR_RES_PLD_SUM: begin
        PRDATA[7:0] = res_payload_sum_i;
      end

      ADDR_RES_PLD_XOR: begin
        PRDATA[7:0] = res_payload_xor_i;
      end

      ADDR_ERR_FLAG: begin
        PRDATA[0] = length_error_i;
        PRDATA[1] = type_error_i;
        PRDATA[2] = chk_error_i;
      end

      default: begin
        if (pkt_mem_addr_valid)
          PRDATA = pkt_mem_rd_data_i;
      end
    endcase
  end
end



endmodule

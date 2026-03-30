# SystemVerilog 验证平台

[TOC]

## 验证导论

SystemVerilog 硬件验证语言(Hard Verification Language，HVL)

具有以下性质；
1. 受约束的随机激励生成
2. 功能覆盖率
3. 更高层次的结构,尤其是面向对象的编程
4. 多线程及线程间通信
5. 支持HDL数据类型,例如verilog的四状态数值
6. 集成了事件仿真器,便于对设计施加控制

验证流程并行于设计流程:对于每个设计模块,设计者首先阅读硬件规范,解析其中的自然语言表述,然后使用RTL代码之类的机器语言创建相应的逻辑

测试平台用于确定待测设计的正确性；
1. 产生激励
2. 把激励施加到DUT上
3. 捕捉响应
4. 检验正确性
5. 对照整个验证目标测算进展情况

### 分层的测试平台

下面是一个不分层的测试平台的例子：

一个用于驱动APB引脚的任务
```verilog
task write(reg[15:0] addr,reg[31:0] data);
    //驱动控制总线
    @(posedge clk)
    PAddr <= addr;
    PWData <= data;
    PWrite<=1'b1;
    PSel<= 1'b1;

    //使PEnable翻转
    @(posedge clk)
    PEnable<=1'b0;
    @(posedge clk)
    PEnable<=1'b1;

endtask

module test(PAddr,PWrite,PSel,PWData,PEnable,Rst,clk);
initial begin
    //初始化
    reset();
    write(16'h50,32'h50);

    if(top.mem.memory[16'h50]!= 32'h50)
        $display("Test failed!");
    else
        $display("Test passed!");
end

endmodule
```

上面代码中:
在 Verilog 的 initial 块中使用 @(posedge clk)，其含义是让当前的执行流程暂停，并等待指定信号（如 clk）的下一个上升沿到来后，再继续执行后续的语句。

#### 信号和命令层

在底部的信号层,包含待测设计和把待测设计连接到测试平台的信号

再往上一层是命令层：执行总线读或写命令的驱动器驱动了待测设计的输入

待测设计的输出与监视器,连监视器负责检测信号的变化,并把这些变化按照命令分组

断言也穿过命令层和信号层,负责监视独立的信号以寻找穿越整个命令的信号变化

#### 功能层

功能层向下面对命令层

代理(VMM中的事务处理器)接收来自上层的事务,例如DMA读或写,把它们分解成独立的命令,这些命令也被送往用于预测事务结果的计分板

检验器负责比较来自监视器和计分板的命令

#### 场景层


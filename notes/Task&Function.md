在 Verilog 中，**task（任务）** 和 **function（函数）** 都是用于封装可重用代码的过程性构造，但它们在用途、能力和限制上有显著差异。以下是详细的对比：

### 核心区别对比

| 特性 | function（函数） | task（任务） |
|---|---|---|
| **返回值** | 必须返回**一个值**（通过函数名返回） | **无返回值**，通过 `output`/`inout` 参数传递结果 |
| **参数类型** | 仅支持 `input` 参数，至少需要一个 | 支持 `input`、`output`、`inout`，参数可为零个或多个 |
| **时序控制** | ❌ 不允许 `#` 延迟、`@` 事件、`wait` 等 | ✅ 允许包含所有时序控制语句 |
| **仿真时间** | 在**零仿真时间**内完成 | 可以跨越**非零仿真时间** |
| **调用方式** | 可作为表达式的一部分调用 | 必须作为独立语句调用 |
| **调用其他构造** | 只能调用其他 function | 可以调用 function 和 task |
| **典型用途** | 纯组合逻辑计算 | 时序逻辑、协议模拟、测试平台 |

### function 示例：组合逻辑计算

```verilog
// 计算8位数据的奇偶校验位
function parity;
    input [7:0] data;
    integer i;
    begin
        parity = 0;
        for (i = 0; i < 8; i = i + 1)
            parity = parity ^ data[i];
    end
endfunction

// 调用方式：可直接在表达式中使用
assign result = parity(data_byte);
```

### task 示例：带时序控制的操作

```verilog
// UART发送任务，包含延迟控制
task uart_send;
    input [7:0] data;
    output tx_line;
    integer i;
    begin
        tx_line = 0;           // 起始位
        #10417;                // 波特率延迟
        for (i = 0; i < 8; i = i + 1) begin
            tx_line = data[i];
            #10417;
        end
        tx_line = 1;           // 停止位
        #10417;
    end
endtask

// 调用方式：必须作为独立语句
initial begin
    uart_send(8'hA5, tx);
end
```

### 使用建议

- **用 function**：当你需要做纯组合逻辑的计算，比如算术运算、位操作、数据格式转换、CRC校验等，且不需要任何延迟或时序控制时。
- **用 task**：当你需要模拟时序行为（如通信协议）、在测试平台中生成激励信号、或者需要多个输出参数时。

### ⚠️ 注意事项

默认情况下，task 和 function 都是**静态（static）**的，多个并发调用会共享同一份变量，可能导致竞态问题。如果需要并发调用，应使用 `automatic` 关键字声明为可重入，让每次调用拥有独立的栈帧变量：

```verilog
task automatic my_task;
    input [7:0] val;
    integer i;  // 每次调用都有独立的 i
    // ...
endtask
```
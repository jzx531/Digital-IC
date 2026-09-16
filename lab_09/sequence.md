SVA（SystemVerilog Assertions）用于检查信号是否满足规定的行为，尤其适合验证“某个事件发生后，若干个时钟周期内必须出现另一个事件”。

其中三个核心概念是：

| 概念 | 作用 |
|---|---|
| `sequence` | 描述信号在多个采样时刻上的匹配模式 |
| `property` | 描述必须满足的规则，可以包含 sequence 和条件关系 |
| `assert property` | 启动检查，规则违反时报告错误 |

### 1. sequence：描述时序模式

```systemverilog
sequence s_req_ack;
  @(posedge clk)
  req ##2 ack;
endsequence
```

意思是：在某个上升沿采到 `req=1`，再过两个上升沿采到 `ack=1`，这个 sequence 就匹配成功。

```text
采样周期      T0    T1    T2
req           1     ×     ×
ack           ×     ×     1
```

`×` 表示不关心。这里没有要求 `req` 保持为 1，也没有限制 T0、T1 的 `ack`。

sequence 只是描述模式，**定义它不会自动启动检查，也不会产生激励。**

### 2. `##`：按照采样周期延迟

```systemverilog
a ##1 b;        // a 成立后，下一个采样周期 b 成立
a ##[1:3] b;    // a 成立后，第 1～3 个周期中至少有一个周期 b 成立
a ##0 b;        // a、b 在同一个采样周期成立
```

`##2` 是两个采样周期，不是 `#2` 那样的两个仿真时间单位。

### 3. 重复匹配

```systemverilog
a[*3]           // a 连续三个采样周期成立
a[*2:4]         // a 连续成立 2～4 个周期
a[*3] ##1 b     // a 连续三个周期成立，然后下一周期 b 成立
```

例如 `a[*3] ##1 b`：

```text
采样周期      T0    T1    T2    T3
a             1     1     1     ×
b             ×     ×     ×     1
```

`[*]` 表示连续重复；`[->]`、`[=]` 表示允许间隔的重复，且结束位置规则不同，不能直接互换。

### 4. property：把模式变成条件规则

```systemverilog
sequence s_ack;
  ##[1:3] ack;
endsequence

property p_req_ack;
  @(posedge clk) disable iff (!rst_n)
  req |-> s_ack;
endproperty

assert property (p_req_ack)
  else $error("ack did not arrive within 1 to 3 cycles");
```

这表示：**只要某个上升沿采到 `req=1`，之后第 1～3 个周期内必须采到 `ack=1`。**复位期间禁用检查。

`|->` 和 `|=>` 的区别：

```systemverilog
req |-> ack;    // req 成立时，同一周期 ack 必须成立
req |=> ack;    // req 成立时，下一周期 ack 必须成立
```

更准确地说，右侧分别从左侧匹配的**结束周期**、结束后的**下一周期**开始。因此：

```systemverilog
(a ##2 b) |-> c;  // c 在 b 匹配的周期检查
(a ##2 b) |=> c;  // c 在 b 匹配后的下一周期检查
```

### 5. 两个容易混淆的地方

`assert property (@(posedge clk) req ##2 ack);` 会每周期启动匹配，要求当前 `req=1`、两周期后 `ack=1`，**不是“如果 req 出现才检查”**。条件检查应使用 `|->` 或 `|=>`。

另外，`req |-> ...` 在 `req` 不成立时不会检查后续响应，这称为空真。如果只希望在请求从 0 变成 1 时触发，可以使用 `$rose(req)`；若 `req` 连续三周期为 1，直接写 `req` 会启动三次独立检查。


如果说的是 **SVA 在 `@(posedge clk)` 上采样**，通常不能在这个上升沿采到刚驱动出的 `a=1`，采到的仍是更新前的 `a=0`。

例如：

```systemverilog
always @(posedge clk)
  a <= 1'b1;

assert property (@(posedge clk) a);
```

同一仿真时刻的调度顺序是：

| 调度区域 | 发生的操作 |
|---|---|
| Preponed | SVA 采样，记录旧值 `a=0` |
| Active | 执行 `a <= 1'b1`，安排更新 |
| NBA | 非阻塞赋值更新，`a` 变成 1 |
| Observed | SVA 使用之前采到的 `a=0` 求值 |

因此，**虽然断言求值时 `a` 已经变成 1，但断言使用的是上升沿更新前的采样值**。若 `a` 保持为 1，下一个上升沿才能采到它。

即使把驱动改成阻塞赋值：

```systemverilog
always @(posedge clk)
  a = 1'b1;
```

并发 SVA 在这个上升沿仍采到旧值，因为 Preponed 采样早于 Active 中的赋值。

不过，普通过程代码不同：

```systemverilog
always @(posedge clk)
  assert (a);  // 立即断言，不是并发 SVA
```

它在过程执行时读取当前值；如果另一个上升沿过程用阻塞赋值更新 `a`，两个过程之间可能发生竞争，不能保证读到哪个值。

所以验证中常用：**在下降沿驱动，在上升沿采样**，或者使用 clocking block 明确驱动和采样时序。

* 在序列,属性和断言语句中都可以定义时钟

```systemverilog
sequence s5a;
  a ##2 b;
endsequence

property p5a;
  @(posedge clk) s5a;
endproperty

a5a: assert property (p5a);
```

* 建议在属性中指定时钟,并保持序列独立于时钟,这样可以提高基本序列定义的可重用性

断言执行块

```systemverilog
property p7;
  @(posedge clk) a ##2 b;
endproperty

a7: assert property (p7);
       $display("p7 succeeded\n");
    else
       $display("p7 failed\n");
```

```systemverilog
@(posedge clk)
a |-> ##[1:$] b ##[0:$] c;
```
含义是：
1. 某个时钟上升沿采到 a == 1。
2. 从 a 所在周期之后至少 1 个周期开始，等待某个 b == 1 的周期。
3. 从匹配到 b 的那个周期开始，等待 c == 1。
4. c 可以和 b 同周期出现，因为是 ##[0:$]。


* SVA还提供了使用序列的结束点作为同步点的连接机制

```systemverilog
sequence s15a;
  @(posedge clk) a ##1 b;
endsequence

sequence s15b;
  @(posedge clk) c ##1 d;
endsequence


property p15a;
  s15a |=> s15b;
endproperty

property p15b;
  s15.ended |-> ##2 s15b.ended;
endproperty

a15a: assert property (p15a);
a15b: assert property (p15b);
```

内嵌的系统任务$past ，可以得到信号在几个时钟周期之前的值，默认情况下,它提供信号在前一个时钟周期的值

$past(signal_name , number_Of_clock cycles)

`[->]` 和 `[=]` 都允许重复项之间不连续。核心区别是：**最后一次匹配之后，sequence 在哪里结束。**

| 写法 | 名称 | 重复之间可有空隙 | sequence 结束位置 |
|---|---|---:|---|
| `b[*3]` | 连续重复 | 否 | 第三个连续的 `b` |
| `b[->3]` | 跟随/Goto 重复 | 是 | 第三次 `b` 所在周期 |
| `b[=3]` | 非连续重复 | 是 | 第三次 `b`所在周期，或其后的空闲周期 |

### `[->]` 跟随重复

```systemverilog
b[->2]
```

表示：

- `b` 必须出现两次；
- 两次之间可以相隔任意多个 `b==0` 的周期；
- sequence 在第二次 `b==1` 的周期结束。

例如：

```text
周期       T0    T1    T2    T3
b          0     1     0     1
                      第一次  第二次并结束
```

结合后续条件：

```systemverilog
a |-> b[->2] ##1 c;
```

第二次 `b` 出现后的下一个周期，`c` 必须成立：

```text
周期       T0    T1    T2    T3    T4
a          1
b                1           1
c                                  1
```

这里 `[->2]` 在 T3 结束，所以 `##1 c` 在 T4 检查。

如果 `c` 在 T6 才出现，则该匹配失败：

```text
周期       T0    T1    T2    T3    T4    T5    T6
a          1
b                1           1
c                                              1
```

因为 `[->2]` 不能吸收第二次 `b` 后的 T4、T5，它固定在 T3 结束。

### `[=]` 非连续重复

```systemverilog
b[=2]
```

同样要求 `b` 出现两次，且两次之间允许存在空隙。但第二次 `b` 出现后，sequence 可以继续匹配若干个 `b==0` 的周期。

因此：

```systemverilog
a |-> b[=2] ##1 c;
```

可以匹配：

```text
周期       T0    T1    T2    T3    T4    T5    T6
a          1
b                1           1     0     0
c                                              1
```

其匹配过程是：

```text
T1：第一次 b
T3：第二次 b
T4～T5：被 b[=2] 的尾部空闲时间吸收
T6：满足 ##1 c
```

所以 `[=]` 更适合表达：

> `b` 出现指定次数，之后某个时刻再出现 `c`，但在 `c` 之前不能再多出现一个 `b`。

如果 T5 又出现一次 `b`：

```text
周期       T0    T1    T2    T3    T4    T5    T6
b                1           1           1
c                                              1
```

那么 `b[=2] ##1 c` 不能将 T5 当成空闲周期，因为在 `c` 前实际已经出现第三次 `b`。

### 等价理解

简化理解可以写成：

```systemverilog
b[->2]
```

近似于：

```systemverilog
!b[*0:$] ##1 b ##1 !b[*0:$] ##1 b
```

最后停在第二个 `b`。

而：

```systemverilog
b[=2]
```

近似于：

```systemverilog
b[->2] ##1 !b[*0:$]
```

它在最后一个 `b` 后还能吸收若干个 `b==0` 的周期。

一句话总结：

- `[->]`：数到最后一次就立即结束。
- `[=]`：数到最后一次后，还可以继续等待后续 sequence。


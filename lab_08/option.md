# SystemVerilog covergroup option 总结

SystemVerilog functional coverage 里，`covergroup`、`coverpoint`、`cross` 都可以带一些内建配置项，用来控制覆盖率的命名、统计、汇总、自动 bins 生成和报告方式。

最常见的写法有两类：

```systemverilog
option.xxx = value;
type_option.xxx = value;
```

`option` 是实例选项，作用在某一个 covergroup 实例、某一个 coverpoint 或某一个 cross 上。它通常影响当前对象的统计或报告。

`type_option` 是类型选项，作用在这个 covergroup 类型整体上。它更像 class 的 static 成员，同一个 covergroup 类型创建出的多个实例会共享这类设置。

不是所有选项都既支持 `option` 又支持 `type_option`，也不是所有选项都能写在 covergroup、coverpoint、cross 三个层级。实际使用时要看该选项的作用对象。

---

## 1. option.name

```systemverilog
covergroup cg @(posedge clk);
  option.name = "rx_packet_cg";
endgroup
```

`option.name` 用来设置 covergroup 实例在 coverage report 里的名字。

它主要用于区分多个 covergroup 实例。例如一个接口有 4 个 channel，每个 channel 都创建一个相同类型的 covergroup，如果不命名，报告里可能只看到工具自动生成的层次名；如果设置 `option.name`，报告会更容易读。

例子：

```systemverilog
covergroup channel_cg(int id) @(posedge clk);
  option.name = $sformatf("channel_%0d_cg", id);
  cp_state: coverpoint state;
endgroup
```

它不影响采样，也不影响 bin 命中，只影响覆盖率数据库和报告中的名字。

---

## 2. option.comment

```systemverilog
covergroup cg @(posedge clk);
  option.comment = "packet type and length coverage";
endgroup
```

`option.comment` 用来给 coverage 对象添加说明文字。

它可以帮助后续看 coverage report 的人理解这个 coverage model 的目的，比如这个 covergroup 是覆盖协议字段、状态机转移，还是错误注入场景。

常见用途：

```systemverilog
covergroup pkt_cg @(posedge clk);
  option.comment = "Cover legal packet length and packet type combinations";

  len_cp: coverpoint pkt_len {
    option.comment = "Packet length categories";
  }

  type_x_len: cross pkt_type, len_cp {
    option.comment = "Packet type versus length";
  }
endgroup
```

它也不影响采样和覆盖率计算，只影响报告可读性。

---

## 3. option.weight

```systemverilog
covergroup cg @(posedge clk);
  addr_cp: coverpoint addr {
    option.weight = 2;
  }

  data_cp: coverpoint data {
    option.weight = 1;
  }
endgroup
```

`option.weight` 是权重，用来影响上一级 coverage 汇总时这个对象占多大比例。

如果所有 coverpoint 权重都是 1，那么 covergroup coverage 通常可以理解成各 coverpoint/cross coverage 的平均值。如果某个 coverpoint 更重要，可以把它的 weight 调大。

例子：

```text
addr_cp coverage = 100%, weight = 2
data_cp coverage =  50%, weight = 1

cg coverage = (100*2 + 50*1) / (2 + 1)
            = 83.33%
```

`weight` 不影响 bin 是否命中，只影响 coverage percentage 的汇总计算。

常见作用域：

```systemverilog
covergroup cg @(posedge clk);
  option.weight = 1;          // covergroup 级别权重

  a: coverpoint addr {
    option.weight = 2;        // coverpoint 级别权重
  }

  b: coverpoint data;

  axb: cross a, b {
    option.weight = 3;        // cross 级别权重
  }
endgroup
```

有些工具中 `weight = 0` 可以让该 coverage item 不计入上一级总分，但仍保留采样和报告。这个行为最好结合具体仿真器报告确认。

---

## 4. option.goal

```systemverilog
covergroup cg @(posedge clk);
  option.goal = 90;

  cp: coverpoint addr {
    option.goal = 100;
  }
endgroup
```

`option.goal` 表示覆盖率目标，通常写成百分比。

例如：

```systemverilog
option.goal = 90;
```

表示这个 coverage 对象达到 90% 就认为满足目标。

注意：`goal` 不会让 coverage 自动变高，也不会改变 bin 的命中条件。它只是告诉 coverage 工具：这个对象的目标覆盖率是多少。

常见用途：

```systemverilog
covergroup smoke_cg @(posedge clk);
  option.goal = 80;  // smoke test 不要求全部覆盖
endgroup

covergroup regress_cg @(posedge clk);
  option.goal = 100; // 回归测试要求完整覆盖
endgroup
```

---

## 5. option.at_least

```systemverilog
covergroup cg @(posedge clk);
  cp: coverpoint state {
    option.at_least = 3;
    bins idle = {0};
    bins busy = {1};
  }
endgroup
```

`option.at_least` 表示每个 bin 至少要命中多少次才算 covered。

默认情况下，一个 bin 命中 1 次通常就算 covered。设置：

```systemverilog
option.at_least = 3;
```

表示每个 bin 需要 hit count >= 3 才算真正覆盖。

例子：

```text
bin idle hit count = 1, at_least = 3 -> 未覆盖
bin busy hit count = 3, at_least = 3 -> 已覆盖
```

它适合用在随机测试中，避免某个值只是偶然出现一次就被认为覆盖充分。

常见作用域是 coverpoint 或 cross：

```systemverilog
cp_addr: coverpoint addr {
  option.at_least = 2;
}

addr_x_cmd: cross cp_addr, cp_cmd {
  option.at_least = 2;
}
```

---

## 6. option.auto_bin_max

```systemverilog
covergroup cg @(posedge clk);
  cp_addr: coverpoint addr {
    option.auto_bin_max = 16;
  }
endgroup
```

`option.auto_bin_max` 控制 coverpoint 自动生成 bins 的最大数量。

如果没有手动定义 bins：

```systemverilog
coverpoint addr;
```

工具会根据 `addr` 的取值范围自动生成 bins。对于很宽的变量，例如 32-bit address，不可能为每个值都生成一个 bin，所以需要一个上限。

例如：

```systemverilog
bit [7:0] addr;

covergroup cg @(posedge clk);
  cp_addr: coverpoint addr {
    option.auto_bin_max = 16;
  }
endgroup
```

`addr` 有 256 个可能值，但 `auto_bin_max = 16`，工具通常会把取值范围自动分成不超过 16 个 bins。

注意：

```systemverilog
coverpoint addr {
  option.auto_bin_max = 16;
  bins zero = {0};
  bins high = {[128:255]};
}
```

显式写出来的 bins 不受 `auto_bin_max` 限制。`auto_bin_max` 主要限制自动生成的 bins。

如果你关心的是 cross 自动 bins，不用 `auto_bin_max`，而是看 `cross_auto_bin_max`。

---

## 7. option.detect_overlap

```systemverilog
covergroup cg @(posedge clk);
  cp: coverpoint addr {
    option.detect_overlap = 1;
    bins low  = {[0:10]};
    bins mid  = {[8:20]};
  }
endgroup
```

`option.detect_overlap` 用来检查 coverpoint 中显式 bins 的取值范围是否有重叠。

上面例子里：

```text
low = 0~10
mid = 8~20
```

`8, 9, 10` 同时属于 `low` 和 `mid`，这就是 overlap。

如果打开：

```systemverilog
option.detect_overlap = 1;
```

工具可以提示这些 bins 有重叠，帮助你发现 coverage model 写得不清楚。

它主要是调试 coverage model 的工具，不改变 DUT 行为，也不改变采样时刻。大型回归中打开 overlap 检查可能增加编译或仿真开销，所以常见做法是调试阶段打开，稳定后关闭。

---

## 8. option.cross_auto_bin_max

```systemverilog
covergroup cg @(posedge clk);
  a: coverpoint addr;
  c: coverpoint cmd;

  axc: cross a, c {
    option.cross_auto_bin_max = 32;
  }
endgroup
```

`option.cross_auto_bin_max` 控制 cross 自动生成 cross bins 的最大数量。

假设：

```text
addr 有 16 个 bins
cmd  有  4 个 bins
```

那么：

```systemverilog
cross addr, cmd;
```

理论上会产生：

```text
16 * 4 = 64 个 cross bins
```

如果设置：

```systemverilog
option.cross_auto_bin_max = 32;
```

工具会限制自动生成的 cross bins 数量。

它和 `option.auto_bin_max` 的区别：

```text
auto_bin_max        -> 控制 coverpoint 自动 bins
cross_auto_bin_max  -> 控制 cross 自动 bins
```

注意：不同标准版本和不同仿真器对 `cross_auto_bin_max` 的支持细节可能不同。实际项目里如果 VCS/Questa/Xcelium 报告行为不一致，需要以工具手册和 coverage report 为准。

---

## 9. option.cross_num_print_missing

```systemverilog
covergroup cg @(posedge clk);
  a: coverpoint addr;
  c: coverpoint cmd;

  axc: cross a, c {
    option.cross_num_print_missing = 20;
  }
endgroup
```

`option.cross_num_print_missing` 控制 coverage report 中最多打印或保存多少个未覆盖的 cross bins。

它经常和 `cross_auto_bin_max` 混淆，但它们不是一回事：

```text
cross_auto_bin_max        -> 影响自动 cross bins 的生成数量
cross_num_print_missing   -> 影响报告中显示多少个 missing cross bins
```

例如一个 cross 有 1000 个组合，最后漏了 300 个。如果：

```systemverilog
option.cross_num_print_missing = 20;
```

报告里可能只列出其中 20 个 missing bins，避免 log 或 report 太大。

它不影响采样，也不影响 coverage 计算结果。没有打印出来的 missing bins 仍然是 missing。

---

## 10. option.per_instance

```systemverilog
covergroup cg @(posedge clk);
  option.per_instance = 1;
  cp: coverpoint addr;
endgroup
```

`option.per_instance` 控制是否保留每个 covergroup 实例自己的覆盖率信息。

假设你创建了两个实例：

```systemverilog
cg cg0 = new();
cg cg1 = new();
```

如果没有打开 per-instance，报告里可能只重点显示这个 covergroup 类型的总体覆盖率。

如果打开：

```systemverilog
option.per_instance = 1;
```

则可以分别看到：

```text
cg0 的 coverage
cg1 的 coverage
```

这在多 channel、多 agent、多 interface 的验证环境里很重要。

例子：

```text
cg0 覆盖 addr = 0~7
cg1 覆盖 addr = 8~15
```

合并看可能是 100%，但单独看每个实例都只覆盖了一部分。`per_instance` 可以帮助你看出这种问题。

---

## 11. option.get_inst_coverage

```systemverilog
covergroup cg @(posedge clk);
  option.per_instance = 1;
  option.get_inst_coverage = 1;
  cp: coverpoint addr;
endgroup
```

`option.get_inst_coverage` 和 covergroup 的两个内建函数有关：

```systemverilog
cg_inst.get_coverage()
cg_inst.get_inst_coverage()
```

一般理解：

```text
get_coverage()       -> 返回 covergroup 类型/合并意义上的覆盖率
get_inst_coverage()  -> 返回当前实例自己的覆盖率
```

但当多个 covergroup 实例需要合并统计时，`get_inst_coverage` 是否能返回真正的 instance coverage，通常还会受到 `type_option.merge_instances` 和 `option.per_instance` 的影响。

常见组合：

```systemverilog
covergroup cg @(posedge clk);
  option.per_instance = 1;
  option.get_inst_coverage = 1;
  type_option.merge_instances = 1;
  cp: coverpoint addr;
endgroup
```

这样既可以保留每个实例自己的覆盖率，又可以让类型覆盖率做合并统计。

如果你只关心 report，不在代码里调用 `get_inst_coverage()`，这个选项的重要性会低一些。

---

## 12. type_option.merge_instances

```systemverilog
covergroup cg @(posedge clk);
  type_option.merge_instances = 1;
  cp: coverpoint addr;
endgroup
```

`type_option.merge_instances` 控制同一个 covergroup 类型的多个实例在计算类型覆盖率时如何合并。

假设有两个实例：

```text
cg0 覆盖 addr = 0
cg1 覆盖 addr = 1
```

如果按 instance 分开看：

```text
cg0 只覆盖一部分
cg1 只覆盖一部分
```

如果 merge instances：

```text
cg 类型整体认为 addr = 0 和 addr = 1 都被覆盖了
```

它和 `option.per_instance` 的关系：

```text
option.per_instance
  控制是否保留/显示每个实例自己的 coverage 信息

type_option.merge_instances
  控制计算 covergroup 类型总体 coverage 时，多个实例是否做 union 合并
```

常见设置：

```systemverilog
option.per_instance = 1;
type_option.merge_instances = 0;
```

适合调试：每个实例分开看，不希望某个实例的覆盖掩盖另一个实例的漏洞。

```systemverilog
option.per_instance = 0;
type_option.merge_instances = 1;
```

适合总体收敛统计：多个实例共同完成同一个 coverage model。

---

## 13. type_option.strobe

```systemverilog
covergroup cg @(posedge clk);
  type_option.strobe = 1;
  cp: coverpoint sig;
endgroup
```

`type_option.strobe` 控制 covergroup 在一个仿真时间槽的较晚区域采样，常用于避免同一个时间点内信号还没有稳定时就采样。

典型场景：

```systemverilog
always @(posedge clk) begin
  a <= b;
end

covergroup cg @(posedge clk);
  type_option.strobe = 1;
  cp: coverpoint a;
endgroup
```

如果不使用 strobe，covergroup 可能在 `posedge clk` 事件发生时就采样，此时 nonblocking assignment 的更新还没有完全反映到目标变量上。

设置：

```systemverilog
type_option.strobe = 1;
```

可以让采样更靠后，通常能采到当前时间槽内更稳定的值。

注意：`strobe` 解决的是同一个 time slot 内的采样区域问题，不会把跨周期的 pipeline 延迟“修正”回来。

---

## 14. 常见作用域总结

| 选项 | 常见作用域 | 主要作用 |
| --- | --- | --- |
| `option.name` | covergroup | 设置实例名字 |
| `option.comment` | covergroup / coverpoint / cross | 给 coverage 对象加说明 |
| `option.weight` | covergroup / coverpoint / cross | 控制汇总覆盖率的权重 |
| `option.goal` | covergroup / coverpoint / cross | 设置目标覆盖率 |
| `option.at_least` | coverpoint / cross | bin 至少命中多少次才算 covered |
| `option.auto_bin_max` | coverpoint | 限制 coverpoint 自动 bins 数量 |
| `option.detect_overlap` | coverpoint | 检查显式 bins 是否重叠 |
| `option.cross_auto_bin_max` | cross | 限制 cross 自动 bins 数量 |
| `option.cross_num_print_missing` | cross | 限制报告中 missing cross bins 的显示/保存数量 |
| `option.per_instance` | covergroup | 保留每个实例自己的 coverage 信息 |
| `option.get_inst_coverage` | covergroup | 配合 `get_inst_coverage()` 获取实例覆盖率 |
| `type_option.merge_instances` | covergroup type | 控制多个实例的类型覆盖率是否合并 |
| `type_option.strobe` | covergroup type | 控制采样区域，减少同一 time slot 内的采样竞态 |

---

## 15. 一个综合例子

```systemverilog
module tb;
  bit clk;
  bit valid;
  bit [7:0] addr;
  bit [1:0] cmd;

  covergroup bus_cg @(posedge clk iff valid);
    option.name = "bus_cg";
    option.comment = "Address and command functional coverage";
    option.per_instance = 1;
    option.get_inst_coverage = 1;
    option.goal = 90;

    type_option.merge_instances = 1;
    type_option.strobe = 1;

    addr_cp: coverpoint addr {
      option.auto_bin_max = 16;
      option.at_least = 2;
      option.detect_overlap = 1;

      bins low  = {[8'h00:8'h3f]};
      bins mid  = {[8'h40:8'hbf]};
      bins high = {[8'hc0:8'hff]};
    }

    cmd_cp: coverpoint cmd {
      option.weight = 2;
      bins read  = {0};
      bins write = {1};
      bins idle  = {2};
      bins err   = {3};
    }

    addr_x_cmd: cross addr_cp, cmd_cp {
      option.weight = 3;
      option.at_least = 1;
      option.cross_num_print_missing = 20;
    }
  endgroup

  bus_cg cg0 = new();
endmodule
```

这个例子里：

```text
option.name/comment
  让报告更容易读

option.per_instance/get_inst_coverage
  允许单独看 cg0 的覆盖率

type_option.merge_instances
  控制多个 bus_cg 实例如何汇总

type_option.strobe
  让采样更靠后，减少同一时间槽内的竞态

option.auto_bin_max
  限制 addr 自动 bins

option.at_least
  要求每个 bin 至少命中指定次数

option.detect_overlap
  检查 bins 范围是否有重叠

option.weight
  调整 coverpoint/cross 对总覆盖率的贡献

option.cross_num_print_missing
  控制 missing cross bins 在报告中显示多少个
```

---

## 16. 使用建议

调试 coverage model 时：

```systemverilog
option.per_instance = 1;
option.get_inst_coverage = 1;
option.detect_overlap = 1;
type_option.merge_instances = 0;
```

这样更容易看出每个实例各自缺了什么。

跑长期 regression 时：

```systemverilog
option.detect_overlap = 0;
option.cross_num_print_missing = 20;
```

这样可以减少报告噪声和额外开销。

对宽变量不要完全依赖自动 bins：

```systemverilog
coverpoint addr;
```

这种写法对 32-bit address 很容易生成意义不强的自动分桶。更推荐按协议语义手动分 bins：

```systemverilog
coverpoint addr {
  bins boot_rom = {[32'h0000_0000:32'h0000_Ffff]};
  bins dram     = {[32'h8000_0000:32'hffff_ffff]};
}
```

一句话总结：

```text
option 控制某个 coverage 对象怎么统计、怎么显示、怎么算分；
type_option 控制这个 covergroup 类型整体怎么统计；
它们通常不改变 DUT 行为，只改变 functional coverage 的采样统计和报告方式。
```

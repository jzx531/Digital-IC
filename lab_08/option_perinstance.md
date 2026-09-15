`option.per_instance` 是 SystemVerilog covergroup 的一个选项，用来控制 **coverage 是否按每个 covergroup 实例分别统计**。

常见写法：

```systemverilog
covergroup cg @(posedge clk);
    option.per_instance = 1;

    cp_addr: coverpoint addr;
endgroup
```

如果你有多个实例：

```systemverilog
cg cg0 = new();
cg cg1 = new();
```

---

默认情况下，很多 coverage 工具会把同一个 covergroup 类型的多个实例合并统计：

```text
cg0 + cg1 汇总成 cg 类型整体覆盖率
```

比如：

```text
cg0 覆盖 addr = 0~7
cg1 覆盖 addr = 8~15
```

合并后可能看起来整体 `addr = 0~15` 都覆盖到了。

---

如果设置：

```systemverilog
option.per_instance = 1;
```

则每个实例单独统计覆盖率：

```text
cg0 单独一份 coverage
cg1 单独一份 coverage
```

这样你可以看到：

```text
cg0 只覆盖了 0~7
cg1 只覆盖了 8~15
```

不会被整体合并结果掩盖。

---

举个简单例子：

```systemverilog
module tb;
    bit clk;
    int addr0, addr1;

    covergroup cg(ref int addr) @(posedge clk);
        option.per_instance = 1;
        cp_addr: coverpoint addr {
            bins low  = {[0:7]};
            bins high = {[8:15]};
        }
    endgroup

    cg cg0 = new(addr0);
    cg cg1 = new(addr1);

    initial begin
        addr0 = 3;
        addr1 = 12;

        #1 clk = 1;
        #1 clk = 0;
    end
endmodule
```

如果 `per_instance = 1`：

```text
cg0: low hit, high not hit
cg1: high hit, low not hit
```

如果不看 per-instance，只看 type coverage：

```text
cg 类型整体：low 和 high 都 hit
```

---

一句话总结：

```systemverilog
option.per_instance = 1;
```

表示：**同一个 covergroup 类型创建多个实例时，每个实例都保留自己独立的覆盖率统计。**

它不影响采样，也不影响 bins 命中，只影响 coverage report 里是否显示/保留每个实例自己的覆盖率。
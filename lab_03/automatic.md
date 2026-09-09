`automatic` 的核心作用是：让变量在每次进入代码块或每次调用任务/函数时，拥有一份独立的存储空间。

可以把它理解成 C/C++ 中的局部栈变量。

### 1. `automatic` 与 `static` 的区别

```systemverilog
task automatic send_packet();
  int count;
endtask
```

每次调用 `send_packet()`，都会产生一个独立的 `count`。因此多个线程并发调用时不会互相覆盖。

而静态变量只有一份：

```systemverilog
task send_packet();
  int count;  // 在静态 task 中，多次调用共享同一个 count
endtask
```

| 类型 | 生命周期 | 并发调用 |
|---|---|---|
| `automatic` | 每次进入时创建，退出后释放 | 每个线程独立 |
| `static` | 整个仿真期间一直存在 | 所有线程共享 |

### 2. 适合并发和递归

```systemverilog
task automatic drive(input int channel);
  int delay;

  delay = $urandom_range(1, 10);
  #delay;
  $display("channel=%0d delay=%0d", channel, delay);
endtask

fork
  drive(0);
  drive(1);
join
```

这里两个 `drive()` 调用拥有各自的 `delay`。如果局部变量是静态的，一个线程可能会覆盖另一个线程的值。

### 3. 在循环和 `fork` 中保存当前值

```systemverilog
forever begin
  automatic rt_packet_t pf;

  wait (pkt.size() > 0);
  pf = pkt.pop_front();

  fork
    begin
      drive_chn1(pf.src, pf.dst, pf.data);
      set_src_chnl_avail(pf);
    end
  join_none
end
```

每次循环都会创建一个新的 `pf`：

```text
第 1 次循环：pf_1 → fork线程1使用
第 2 次循环：pf_2 → fork线程2使用
第 3 次循环：pf_3 → fork线程3使用
```

即使前一个 `fork` 线程还没有运行完，下一次循环也不会覆盖它所使用的 `pf`。

如果使用外部共享变量：

```systemverilog
rt_packet_t p;

forever begin
  p = pkt.pop_front();

  fork
    begin
      drive_chn1(p.src, p.dst, p.data);
    end
  join_none
end
```

所有子线程访问的是同一个 `p`。主线程继续循环后，`p` 可能已经被下一个 packet 覆盖。

### 4. 声明时初始化

自动变量的初始化在每次进入作用域时执行：

```systemverilog
automatic int saved_i = i;
```

每次进入都会把当时的 `i` 保存到新的 `saved_i` 中。

静态变量的声明初始化通常只执行一次：

```systemverilog
static int count = 0;
```

### 5. `automatic` 不等于深拷贝

如果 `rt_packet_t` 是 `struct`，赋值通常复制整个结构体：

```systemverilog
automatic rt_packet_t pf = p;
```

如果 `rt_packet_t` 是 `class`，复制的只是对象句柄：

```systemverilog
automatic rt_packet_t pf = p;
```

此时 `pf` 和 `p` 仍然指向同一个对象。若要得到独立对象，需要实现 `copy()` 或 `clone()`：

```systemverilog
automatic rt_packet_t pf = p.clone();
```

一句话概括：`automatic` 解决的是“变量存储空间是否独立”，并不自动解决对象深拷贝或线程同步问题。
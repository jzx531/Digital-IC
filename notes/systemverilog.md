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

场景层被位于场景层中的发生器驱动,比如mp3播放器,下载存储播放，调整播放内容这些操作的每一个都可以称作场景,场景层负责组织协调这些步骤,操作的参数如音轨大小和寄存器位置等都采用受约束的随机值


![alt text](完整测试平台.png)

顶层的测试包含了用于创建激励的约束

功能覆盖率可以衡量所有测试在满足验证计划要求方面的进展,随着各项测试标准的完成,功能覆盖率代码在整个项目过程中会经常变化

在随机序列中间插入定向测试的代码,或者把两部分代码并列
定向代码执行你期望的任务,而随机的背景噪声可能使漏洞暴漏出来,而且漏洞还有可能是在未期望的模块中

### 建立一个分层的测试平台

驱动器可能会注入错误或者增加时延,然后再把命令分解为一些信号的变化,例如总线请求或握手
事务处理器,核心部分是一个循环:有关事务处理器的师范代码如下:

```verilog
task run();
    done = 0;
    while(!done) begin
    //获取下一个事务
    //进行变换
    //发送事务
    end
endtask
```

### 仿真环境阶段

使项目中的所有代码能够一起工作
三个基本阶段是建立,运行和收尾,每个阶段都可以再细分为更小的步骤；

建立阶段可以分为如下步骤:
1. 生成配置:把待测设计的配置和周围的环境随机化
2. 建立环境:基于配置来分配和连接测试平台构件,测试平台构件指的是存在于测试平台中的部分，与RTL代码描述的设计物理构件区分开:例如如果配置选择了三个总线驱动器,那么测试平台应该在这个阶段对它们进行分配和初始化
3. 对待测设计进行复位
4. 配置待测设计；基于第一步中生成的配置，载入待测设计的命令寄存器

运行阶段指测试实际运行的阶段,可分为以下步骤:
1. 启动环境：运行各种测试平台构件,例如各种BFM和激励发生器
2. 运行测试:启动测试然后等待测试完成,定向测试的完成很容易判断,但随机测试却比较困难,可以使用测试平台的层作为引导,从顶层启动,等待一个层接收完来自上一层的所有输入,接着等待当前层空闲下来,然后再等待下一层

收尾阶段:
1. 清空:在最下层完成以后,等待设计清空最后的事务
2. 报告:一旦待测设计空闲下来,清空遗留在测试平台中的数据,有时保存在积分板利的数据从来就没有送出来过，根据信息创建最终报告,说明测试通过或者失败,如果测试失败，将相应的结果功能覆盖率删除

## 数据类型

SystemVerilog 引进了一些新的数据类型,具有以下优点:
1. 双状态数据类型:更好的性能,更低的内存消耗
2. 队列,动态和关联数组:减小内存消耗,自带搜索和分类功能
3. 类和结构：支持抽象数据结构
4. 联合和合并结构：允许对同一数据有多种视图
5. 字符串:支持内建的字符序列
6. 枚举类型：方便代码编写,增加可读性

### 逻辑logic类型

Verilog中,初学者对经典的reg数据类型进行了改进,使得它除了作为一个变量以外,还可以被连续赋值,门单元和模块所驱动

为了与寄存器类型相区别,这种改进的数据类型被称为logic,任何使用线网的地方均可以使用logic,但要求logic不能有多个结构型的驱动
例如双向总线建模的时候,需要使用线网类型

logic 类型的使用

```systemverilog
module logic_data_type(input logic rst_h);
    parameter CYCLE = 20;
    logic q,q_l,d,clk,rst_l;
    initial begin
        clk = 0;   //过程赋值
        forever # (CYCLE/2) clk = ~clk;   //连续赋值
    end

    assign rst_l = ~rst_h; // 连续赋值
    not n1(q_l,q); // q_1被门驱动
    my_dff d1(q,d,clk,rst_l); //被模块驱动
endmodule
```

由于logic类型只能有一个驱动,所以其可被适用于查找网单中的漏登
如果存在多个驱动时,编译就会出现错误

### 双状态数据类型

相比四状态数据类型: 0 , 1 , X(未知) , Z(高阻态)

双状态数据类型有利于提高仿真性能并减少内存的使用量,最简单的双状态数据类型是bit,它是无符号的,另外四种带符号的双状态数据类型是byte,shortint,int 和longint

```systemverilog
bit b;                //双状态,单比特
bit [31:0] b32;       //双状态,32比特无符号整数
int unsigned ui;      //双状态,32比特无符号整数
int i;                //双状态,32比特有符号整数
byte b8;              //双状态,8比特有符号整数
shortint s;           //双状态,16比特有符号整数
longint l;            //双状态,64比特有符号整数
integer i4;           //四状态,32比特有符号整数
time t;               //四状态,64比特无符号整数
real r;               //双状态,双精度浮点数
```

对于双状态变量,被测设计试图产生X或Z，这些值会被转换成双状态值,而测试代码永远察觉不了

对四状态值的检查：

```systemverilog
if($isunknown(iport) == 1)
    $display("@%0t: 4-state value detected on iport %b", $time, iport);
```

### 定宽数组

定宽数组的声明和初始化
Verilog要求在声明中必须给出数组的上下界,因为几乎所有数组都使用0作为索引下界
所以SystemVerilog允许只给出数组宽度的便捷声明方式,跟C语言类似

定宽数组的声明
```systemverilog
int lo_hi[0:15];        //16个整数[0]...[15]
int c_style[16];         //等价声明方式
```

可以通过在变量后面指定维度的方式来创建多维定宽数组

下面创建了几个二维数组
```systemverilog
int arr[3][4];           //3行4列的整数数组
int arr2[0:2][0:3];     //等价声明方式
arr[1][2] = 1;  //设置元素值
```

很多SystemVerilog仿真器在存放数组元素时使用32比特的字边界,所以byte,shortint和int都是存放在一个字中,而longint则存放到两个字中

在非合并数组中,字的低位用来存放数据,高位则不使用
```systemverilog
bit [7:0] arr[3];       //3个字节的数组
```

### 常量数组

```systemverilog
int ascend[4] = '{1,2,3,4};  //等价声明方式
int descend[4];
descend = '{4,3,2,1};

<!-- 为前三个元素赋值 -->

descend[0:2] = '{3,2,1};  //等价声明方式
ascend ='{4{8}}; //四个值全部为0
descend = '{9,8,default:1};
```

基本的数组操作:for和foreach

在数组操作中使用for和foreach循环
```systemverilog
initial begin
    bit [31:0] src[5],dst[5];
    for(int i = 0;i<$size(src);i++)
        src[i] = i;
    foreach(dst[j])
        dst[j] = src[j]*2; //dst的值是src的两倍
    end
```

初始化并遍历多维数组
```systemverilog
int md[2][3] = '{'{1,2,3},'{4,5,6}}; //二维数组的初始化
initial begin
    $display("Initial value:");
    foreach(md[i,j])  //这是正确的语法格式
        $display("md[%0d][%0d] = %0d", i, j, md[i][j]);
    $display("New value:");
    md = '{'{7,8,9},'{3{32'd5}}}; //修改数组元素
    foreach(md[i,j])
        $display("md[%0d][%0d] = %0d", i, j, md[i][j]);
end
```

```systemverilog
initial begin
    byte twoD[4][6];
    foreach(twoD[i,j])
        twoD[i][j] = i*10+j;

    foreach(twoD[i]) begin //遍历第一个维度
        $write("%2d: ", i);
        foreach(twoD[,j]) //遍历第二个维度
            $write("%0d ", twoD[i][j]);
        $display("");
    end
end
```

### 基本的数组操作 ----复制和比较

数组的复制和比较操作

```systemverilog
initial begin
    bit [31:0] src[5] = '{1,2,3,4,5},
               dst[5] = '{5,4,3,2,1};
    
    //两个数组的聚合比较
    if(src == dst)
        $display("src == dst");
    else
        $display("src!= dst");
    dst = src; //复制src到dst
    // 只改变一个元素的值
    src[0] = 5;
    //所有元素的值是否相等(否！)
    $display("src == dst: %b", (src == dst)? "==":"!=");

    //使用数组片段对第1-4个元素进行比较
    $display("src[1:4] %s dst[1:4]",(src[1:4] == dst[1:4])? "==":"!=");
end
```

同时使用位下标和数组下标

```systemverilog
initial begin
    bit [31:0] arr[5] = '{5{5}};
    $display(src[0],,src[0][0],,src[0][2:1]);
    //使用位下标访问数组元素
end
```

```systemverilog
bit [3:0][7:0] bytes; //4个字节组装成32比特
bytes = 32'hCafe_Data;
$displayh(bytes,, //显示所有32比特
          bytes[3],, //最高字节“CA” 两个h为一个字节
          bytes[3][7]); //最高比特位“1”
```

合并/非合并混合数组的声明

```systemverilog
bit [3:0][7:0] barray [3];   //合并:3x32比特
bit [31:0] lw = 32'h0123_4567; //字
bit [7:0][3:0] nibbles;       //合并数组
barray[0] = lw;
barray[0][3] = 8'h01;
barray[0][1][6] = 1'b1;
nibbles = barray[0]; //非合并数组
```

合并数组和非合并数组的选择

动态数组在声明时使用空的下标[]，即数组的宽度不在编译时给出而在程序运行时再指定

数组最开始时是空的,所以你必须调用new[]操作符来分配空间,同时在方括号中传递数组宽度

```systemverilog
int dyn[],d2[]; //声明动态数组

initial begin
    dyn = new[5];  //分配5个元素
    foreach(dyn[j]) dyn[j] = j; //对元素进行初始化
    d2 = dyn;       //复制一个动态数组
    d2[0] = 5;      //修改复制值
    $display("dyn[0] = %0d, d2[0] = %0d", dyn[0], d2[0]);
    dyn = new[20](dyn);    //分配20个整数值并进行复制
    dyn = new [100];       //分配100个元素的数组,旧值将不存在
    dyn.delete();          //删除所有元素
end
```

### 队列

队列结合了链表和数组的优点
队列和链表相似,可以在一个队列中任何地方增加或者删除元素,这类操作在性能上的损失比动态数组小得多,因为动态数组需要分配新的数组并复制所有元素的值,队列与元素相似,可以通过索引实现对任意元素的访问,而不需要像链表那样去遍历目标元素之前的所有元素

队列的操作

```systemverilog
int j = 1,
    q2[$] = {3, 4},       // 队列的常量不需要使用“ ' ”
    q[$] = {0, 2, 5};     // {0, 2, 5}

initial begin
    q.insert(1, j);       // {0, 1, 2, 5}    在 2 之前插入 1
    q.insert(3, q2);      // {0, 1, 2, 3, 4, 5} 在 q 中插入一个队列①
    q.delete(1);          // {0, 2, 3, 4, 5} 删除第 1 个元素
end

// 下面的操作执行速度很快
q.push_front(6);          // {6, 0, 2, 3, 4, 5} 在队列前面插入
j = q.pop_back;           // {6, 0, 2, 3, 4}    j = 5
q.push_back(8);           // {6, 0, 2, 3, 4, 8} 在队列末尾插入
j = q.pop_front;          // {0, 2, 3, 4, 8}    j = 6

foreach (q[i])
    $display(q[i]);       //                    打印整个队列

q.delete();               // {}                 删除整个队列
```

```SystemVerilog
// 例 2.20 队列操作
int j = 1,
    q2[$] = {3, 4},       // 队列的常量不需要使用“ ' ”
    q[$] = {0, 2, 5};     // {0, 2, 5}

initial begin
    // 结果
    q = {q[0], j, q[1:$]};      // {0, 1, 2, 5} 在 2 之前插入 1
    q = {q[0:2], q2, q[3:$]};   // {0, 1, 2, 3, 4, 5} 在 q 中插入一个队列
    q = {q[0], q[2:$]};         // {0, 2, 3, 4, 5} 删除第 1 个元素

    // 下面的操作执行速度很快
    q = {6, q};                 // {6, 0, 2, 3, 4, 5} 在队列前面插入

    // ① 并不是所有的 SystemVerilog 仿真器都支持使用 insert() 对队列插入新值。

    j = q[$];                   // 等同于 j = 5
    q = q[0:$ - 1];             // {6, 0, 2, 3, 4} 从队列末尾取出数据
    q = {q, 8};                 // {6, 0, 2, 3, 4, 8} 在队列末尾插入
    j = q[0];                   // 等同于 j = 6
    q = q[1:$];                 // {0, 2, 3, 4, 8} 从队列前面取出数据

    q = {};                     // {} 删除整个队列
end
```

### 关联数组

关联数组采用在方括号中放置数据类型的形式来进行声明,例如[int]或[packet]

关联数组的声明,初始化和使用

```systemverilog
initial begin
    bit[63:0] assoc[bit[63:0]],idx = 1;

    //对稀疏分布的元素进行初始化
    repeat (64) begin
        assoc[idx] = idx;
        idx = idx << 1;
    end

    //使用foreach遍历数组
    foreach(assoc[i])
        $display("assoc[%0d] = %0d", i, assoc[i]);
    
    //使用函数遍历数组
    // 使用 foreach 遍历数组
    foreach (assoc[i])
        $display("assoc[%h]=%h", i, assoc[i]);

    // 使用函数遍历数组
    if (assoc.first(idx))
        begin                   // 得到第一个索引
            do
                $display("assoc[%h]=%h", idx, assoc[idx]);
            while (assoc.next(idx)); // 得到下一个索引
        end

    // 找到并删除第一个元素
    assoc.first(idx);
    assoc.delete(idx);
    $display("The array now has %0d elements", assoc.num);
end

```

使用带字符索引的关联数组

```systemverilog

int switch[string],min_address,max_address;
initial begin
    int i,r,file;
    string s;
    file = $fopen("switch.txt","r");
    while(!$feof(file)) begin
      r = $fscanf(file,"%s %d %d",s,i,r);
      switch[s] = i;
end
$fclose(file);

// 获取最小地址值
min_address = switch["min_address"];

// 获取最大地址值,缺省为1000
if(switch.exists("max_address"))
    max_address = switch["max_address"];
else
    max_address = 1000;

//打印数组的所有元素
foreach(switch[s])
    $display("switch[%s] = %d", s, switch[s]);
end

```
            
### 数组方法

```systemverilog

    bit on[10];   //单比特数组
    int total;   

    initial begin
    foreach(on[i])
        on[i] = i;

    //打印出单比特和
    $display("on.sum = %0d", on.sum);

    //打印出单比特和
    $display("on.sum = %0d", on.sum + 32'd0);

    // 由于 total 是 32 比特 变量，所以数组和也是32 比特
    total = on.sum;
    $display("total = %0d", total);

    // 将数组和与一个32比特进行比较
    if(on.sum >= 32'd5)
    $display("sum has 5 or more bits");

    // 使用带32bit有符号运算的with表达式
    $display("on.sum with 32-bit signed addition = %0d", on.sum.with(32'sd0));
end

```

如果想从一个关联数组中随机选取一个元素,需要逐个访问它之前的元素
原因是没有办法直接访问到第N个元素


从一个关联数组中随机选取一个元素

```systemverilog
int aa[int],rand_idx,element_count;

element = $urandom_range(aa.size() - 1);

foreach(aa[i])
    if(count++ == element) begin
        rand_idx = i;
        break;
    end
    $display("0d element aa[%0d] = %0d", rand_idx, aa[rand_idx]);
```


####  数组定位方法

```systemverilog
int f[6] = '{1,6,2,6,8,6};

tq = q.min();
tq = d.max();
tq = f.unique();

tq = d.find with(item > 3);
tq.delete();
foreach(d[i])
  if(d[i] > 3)
    tq.push_back(d[i]);

tq = d.find_index with(item > 3);
tq = d.find_first with(item > 99);
tq = d.find_first_index with(item == 8);
tq = d.find_last with(item == 4);
tq = d.find_last_index with(item == 4);
```

数组定位方法

```systemverilog
int count,total,d[] = '{9 , 1 , 8 , 3 ,4 ,4};  

count = d.sum_with(item > 7);// 2 ：{9，8}

total = d.sum with((item > 7) * item);  // 17 = 9  + 8

count = d.sum with(item < 8);

```

### 数组的排序

```systemverilog

int d [] = '{9 , 1 , 8 , 3 ,4 ,4};  
d.reverse();
d.sort();
d.rsort();
d.shuffle();

struct packed {byte red,green,blue;} c[];

initial begin
    c = new[100];
    foreach(c[i])
        c[i] =$urandom;
    c.sort with(item.red);

    c.sort with({x.green,x.blue});

end
```

使用数组定位方法建立计分板

```systemverilog
typedef struct packed
{
    bit[7:0]addr;
    bit[7:0] pr;
    bit[15:0] data;
} Packet;

Packet scb[$];

function void check_addr(bit [7:0] addr);
    int into[$];

    intq = scb.find_index() with(item.addr == addr);
    case(intq.size())
    0: $display("Addr %h not found in scoreboard",addr);
    1: scb.delete(intq[0]);
    default:
        $display("Error : Multiple hits for addr %h",addr);

    endcase
endfunction : check_addr

```

### 使用typedef 创建新的类型

Verilog 中用户自定义的类型宏
```verilog
`define OPSIZE 8
`define OPREG reg[`OPSIZE-1:0]

`OPREG op_a,op_b;
```

```SystemVerilog
parameter OPSIZE = 8;
typedef reg[OPSIZE-1:0] opreg_t;

opreg_t op_a,op_b;
```

uint的定义
```SystemVerilog
typedef bit [31:0] uint;
typedef int unsigned uint; //等效的定义
```


用户自定义数组类型
```systemverilog
typedef int fixed_array5[5];
fixed_array5 f5;

initial begin
    foreach(f5[i])
        f5[i] = i;
end
```

使用struct 创建新类型
```SystemVerilog
struct {bit[7:0] r,g,b;} pixel;

typedef struct {bit[7:0] r,g,b;} pixel_s;
pixel_s my_pixel;
```

对结构体进行初始化

对struct 类型进行初始化

```systemverilog

initial begin 
    typedef struct {
        int a;
        byte b;
        shortint c;
        int d;
    }my_struct_s;

    my_struct_s st = '{32'haaaa_aaaad,8'hbb,16'hcccc,32'hdddd_dddd};
    $display("st.a = %0d, st.b = %0d, st.c = %0d, st.d = %0d", st.a, st.b, st.c, st.d);
    end
```

创建可容纳不同类型的联合
```SystemVerilog
typedef union {int i ; real f;} num_u;
num_u un;
un.f = 0.0; //把数值设置为浮点形式

```

合并结构

pixel使用三个数值,所以它占用了三个长字的存储空间,即使它实际只需要三个字节
```SystemVerilog
typedef struct packed {
    bit[7:0] r;
    bit[7:0] g;
    bit[7:0] b;
} pixel_p_s;

pixel_p_s p;
```

### 类型转换

静态转换

在整型和实型之间进行静态转换
```SystemVerilog
int i;
real r;

i = int '(10.0 - 0.1); //转换为非强制的
r = real '(42);
```


动态转换

$cast动态转换函数允许对越界的数值进行检查

流操作符

```systemverilog
initial begin
    int h;
    bit [7:0] b, g[4], j[4] = '{8'ha, 8'hb, 8'hc, 8'hd};
    bit [7:0] q, r, s, t;

    h = {>>{j}};                // 0a0b0c0d- 把数组打包成整型
    h = {<<{j}};                // b030d050 位倒序
    h = {<<byte{j}};            // 0d0c0b0a 字节倒序
    g = {<<byte{j}};            // 0d,0c,0b,0a 拆分成数组
    b = {<<{8'b0011_0101}};     // 1010_1100 位倒序
    b = {<<4{8'b0011_0101}};    // 0101_0011 半字节倒序
    {>>{q,r,s,t}} = j;          // 把 j 分散到四个字节变量里
    h = {>>{t,s,r,q}};          // 把字节集中到 h 里
end
```


也可以使用很多连接符来完成同样的操作

数组元素会根据需要自动分配

```SystemVerilog
initial begin
    bit [15:0] wq[$] = '{16'h1234, 16'h5678, 16'h9abc,16'ddef0};
    bit [7:0] bq[$];

    // 把字数组转换成字节数组
    bq = {>>{wq}}; // 12 34 56 78

    // 把字节数组转换成字数组
    bq = {8'h98, 8'h76, 8'h54, 8'h32};
    wq = {>>{bq}}; // 98 76 54 32
end
```

流操作符也可用来将结构打包或者拆分到字节数组中

```SystemVerilog
initial begin
  typedef struct {
    int a;
    byte b;
    shortint c;
    int d;
  }my_struct_s;

  my_struct_s st = '{32'haaaa_aaaad,8'hbb,16'hcccc,32'hdddd_dddd};

  byte b[];

  //将结构转换成字节数组
  b = {>> {st}}; // aa aa aa aa bb cc cc dd dd dd dd

  //将字节数组转换成结构
  my_struct_s st2;
  st2 = {>> {b}}; // st2.a = 32'haaaa_aaaad, st2.b = 8'hbb, st2.c = 16'hcccc, st2.d = 32'hdddd_dddd
end
```


### 枚举类型

enum {RED,BLUE,GREEN} color;

```SystemVerilog
// 创建代表 0,1,2 的数据类型
typedef enum {INIT, DECODE, IDLE} fsmstate_e;
fsmstate_e pstate, nstate;       // 声明自定义类型变量

initial begin
    case (pstate)
        IDLE: nstate = INIT;     // 数据赋值
        INIT: nstate = DECODE;
        default: nstate = IDLE;
    endcase
    $display("Next state is %s",
             nstate.name());     // 显示状态的符号名
end
```

1. first() 返回第一个枚举常量
2. last() 返回最后一个枚举常量
3. next() 返回下一个枚举常量
4. next(N) 返回以后第N个枚举常量
5. prev() 返回前一个枚举 变量
6. prev(N) 返回以前第N个枚举常量


### 常量

```SystemVerilog
// 常量声明
initial begin 
    const byte colon = ":";
end
```

字符串方法

```SystemVerilog
string s ;
initial begin
    s = "IEEE";
    $display(s.getc(0));
    $display(s.tolower());

    s.putc(s.len()-1,"-");
    s = s(s,"P1800");

    $display(s.substr(2,5));

    my_log($psprintf("s = %s %5d",s,42));
end

task my_log(string message);
    $display("@%0t: %s", $time, message);
endtask
```

# Senior Fpga Design

## Fast Speed Structure

例如下面的例子是一个递归的算法,相同的变量和地址被存取直到计算完成,因为微处理器一次只执行一个指令,所以没有利用并行性

```verilog
module power3(
    output [7:0] XPower,
    output       finished,
    input  [7:0] X,
    input  clk,start); //the duration of start is a single clock

    reg [7:0] ncount;
    reg [7:0] XPower;

    assign finished = (ncount == 0);

    always @ (posedge clk)
        if(start) begin
            XPower <= X;
            ncount <= 2;
        end
        else if(!finished) begin
            ncount <= ncount - 1;
            XPower <= XPower * X;
        end
endmodule
```

与相同算法的流水线版本对比

```verilog
module power3(
    output reg [7:0] XPower,
    input      clk,
    input      [7:0] X
);

reg [7:0] XPower1,XPower2;
reg [7:0] X1,X2;
always @(posedge clk) begin
    //pipeline stage 1
    X1 <= X;
    XPower1 <= X;

    //pipeline stage 2
    X2 <= X1;
    XPower2 <= XPower1 *  X1;

    //pipeline stage 3
    XPower <= XPower2 * X2;
end
endmodule

```
流量的性能超过了迭代实现的三倍

为了产生并行结构,可以将乘法器分解为独立的操作,然后重新组合他们

```verilog
module power3(
    output [7:0] XPower,
    input  [7:0] X,
    input clk
);

reg [7:0] XPower1,
//partial product registers
reg [3:0] XPower2_ppAA,XPower2_ppAB,XPower2_ppBB;
reg [3:0] XPower3_ppAA,XPower3_ppAB,XPower3_ppBB;
reg [7:0] X1,X2;
wire [7:0] XPower2;

wire [3:0] XPower1_A     = XPower1[7:4];
wire [3:0] XPower1_B     = XPower1[3:0];
wire [3:0] X1_A          = X1[7:4];
wire [3:0] X1_B          = X1[3:0];
wire [3:0] XPower2_A     = XPower2[7:4];
wire [3:0] XPower2_B     = XPower2[3:0];
wire [3:0] X2_A          = X2[7:4];
wire [3:0] X2_B          = X2[3:0];

assign XPower2 = (XPower2_ppAA << 8) + (2 * XPower2_ppAB <<4) + XPower2_ppBB;
assign XPower  = (XPower3_ppAA << 8) + (2 * XPower3_ppAB <<4) + XPower3_ppBB;

always @(posedge clk) begin
    //pipeline stage 1
    X1 <= X;
    XPower1 <= X;
    //pipeline 2
    X2 <= X1;
    //create partial products
    XPower2_ppAA <= XPower1_A * X1_A;
    XPower2_ppAB <= XPower1_A * X1_B;
    XPower2_ppBB <= XPower1_B * X1_B;

    //pipeline stage 3
    //create partial products
    XPower3_ppAA <= XPower2_A * X2_A;
    XPower3_ppAB <= XPower2_A * X2_B;
    XPower3_ppBB <= XPower2_B * X2_B;
end
endmodule

```
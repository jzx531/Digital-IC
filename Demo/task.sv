`timescale 1ns/1ps

module tb;
    // 只有 input 可以有默认值，output 不能有
    task mytask3(input [7:0] x = 8'd4, input [7:0] y = 8'd6, output [15:0] z);
        #5ns;
        z = x * y - 1;
        return;
        #5ns;
    endtask

    byte unsigned a = 3;
    byte unsigned b = 4;
    byte unsigned c;

    initial begin
        // 1. 正常调用：传入 a, b，结果存入 c
        mytask3(a, b, c);
        
        // 2. 命名参数调用：只传 z，x 和 y 使用默认值 4 和 6
        // 此时 c = 4 * 6 - 1 = 23
        mytask3(.z(c));
        
        $display("Final c = %0d", c);
    end

    initial begin
        repeat(15) begin
            #1ns;
            $display("@time %0t, c = %0d", $time, c);
        end
    end

endmodule
module tb;
    function [15:0] myfunc2(input [7:0] x,input [7:0] y);
        myfunc2 = x * y -1;
    endfunction

    function automatic void myfunc3(input [7:0] x,input [7:0] y,output [15:0] z);
        z = x * y -1;
    endfunction

    initial begin
        byte unsigned a = 3;
        byte unsigned b = 4;
        byte unsigned c;
        myfunc3(a,b,c);
        $display("c = %0d",c);
    end

endmodule

 
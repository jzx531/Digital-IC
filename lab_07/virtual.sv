module tb;

class BasePacket;
// 成员变量不能添加virtual,只有成员函数添加virtual
    int A = 1;
    int B = 2;
    function void printA;
        $display("BasePacket A is %d",A);
    endfunction

    virtual function void printB;
        $display("BasePacket B is %d",B);
    endfunction
endclass : BasePacket

class My_Packet extends BasePacket;
    int A = 3;
    int B = 4;
    function void printA;
        $display("My_Packet A is %d",A);
    endfunction: printA

    virtual function void printB;
        $display("My_Packet B is %d",B);
    endfunction: printB

endclass : My_Packet

BasePacket P1 = new;
My_Packet P2 = new;

initial begin
    P1.printA;
    P1.printB;
    P2.printA;
    P2.printB;

    P1 = P2;
    P1.printA;
    P1.printB; //virtual会将作用域也绑定到多态的子类作用域中
end


endmodule :tb;
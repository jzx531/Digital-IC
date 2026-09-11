package pkg_a;
    class packet_a;
    endclass
    int va = 6;
    typedef struct {int data; 
            int command;} struct_a;

    int shared = 9;
endpackage

// 模块无法定义在package里
// interface也无法定义在package里，即偏向于硬件的代码内容不能定义在package中

package pkg_b;
    class packet_b;
    endclass
    int vb = 8;
    typedef struct {int data; 
            int command;} struct_b;

    int shared = 10;
endpackage

module tb;

    class packet_tb;
    endclass

    typedef struct{
        int data;
        int command;
    } struct_tb;

    /**
    * @brief 直接导入，会和module内的重名内容发生冲突 
    */
    import pkg_a::packet_a;
    import pkg_b::packet_b;
    import pkg_a::va;
    import pkg_b::vb;
    import pkg_a::struct_a;
    import pkg_b::struct_b;

    /**
    * @brief 使用通配符导入，不会和module内的重名内容发生冲突
    * @note  指的是当module内没找到的内容会在pkg_a和pkg_b中查找 
    * @note  存在同名的内容时，需要使用作用域限定符来区分
    */
    import pkg_a::*;
    import pkg_b::*;

    

    class packet_a;
    endclass

    class packet_b;
    endclass

    initial begin
        pkg_a::packet_a pa = new();
        pkg_b::packet_b pb = new();
        packet_tb ptb = new();
        $display("va = %d, vb = %d", pkg_a::va, pkg_b::vb);
    end
endmodule



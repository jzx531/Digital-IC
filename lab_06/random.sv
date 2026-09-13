class packet;
    rand bit [31:0] src,dst,data[8];
    rand bit [7:0] kind;
    constraint cstr{
        src > 10;
        src < 15;
    }
    function string print();
        $display("src is %0d,dst is %0d,data is %p\n",this.src,this.dst,this.data);
    endfunction
endclass

module tb;
 initial begin
    packet p;
    initial begin
        p = new();
        p.print();
        p.randomize();
        $display("after randomize\r\n");
        p.print();
    end
end
endmodule

typedef struct{
    rand bit [31:0] src;
    rand bit [31:0] dst;
    rand bit [31:0] data [4];
    rand bit [7:0] kind;
} packet_t;

module tb2;
    // rand packet_t pkt;
    packet_t pkt;
    initial begin
        // pkt.randomize();
        std::randomize(pkt);
        std::randomize(pkt) with {pkt.kind == 1; pkt.src > 10; pkt.src < 15};// dynamic constraint
        $display("after randomize\r\n");
        $display("src is %0d,dst is %0d,data is %p\n",pkt.src,pkt.dst,pkt.data);
    end
endmodule

module tb3;
    bit [31:0] src,dst;
    bit [31:0] data [4];
    bit [7:0] kind;
    initial begin
        src = $urandom();
        dst = $urandom();
        data = {$urandom(),$urandom(),$urandom(),$urandom()};
        kind = $urandom();
        std::randomize(kind) with {kind == 1; src > 10; src < 15};// dynamic constraint
        $display("after randomize\r\n");
        $display("src is %0d,dst is %0d,data is %p\n",src,dst,data);
    end
endmodule

module tb4;
    class packet;
    rand byte arr[];
    constraint cstr{
        foreach arr[i] arr[i] inside{2,4,6,8};
        foreach arr[i] arr[i] > 2*i;
        arr.size() < 20;
    }
    endclass
    initial begin
        packet p = new();
        repeat(10) begin
            if(p.randomize()) $display("arr size is %d,data is %p\n",p.arr.size(),p.arr);
            else $error("randomize failed\n");
        end
    end
endmodule

module tb5;
    class packet_a;
        rand int length;
        // constraint cstr{length inside {[5:15]};}
        constraint cstr1{soft length inside {[5:15]};}
    endclass

    class packet_b extends packet_a;
        // 子类同名约束覆盖父类
        // constraint cstr{length inside {[10:20]};}
        // 不同名不覆盖，发生冲突时通过给父类添加soft，从而服从子约束
        constraint cstr2{length inside {[10:20]};}
    endclass

    initial begin
        packet_b pkt = new();
        repeat(100) begin
            if(pkt.randomize()) $display("length is %d\n",pkt.length);
            else $error("randomize failed\n");

            // 非必要，不要设置成都是软约束，防止约束错用
            // 都使用软约束时,使用就近原则的约束
            if(pkt.randomize()) with {soft length inside {[21:25]};}$display("length is %d\n",pkt.length);
            else $error("randomize failed\n");   
        end
    end

endmodule

module tb6;
    class packet1;
        rand bit [7:0] x;
    endclass

    class packet2;
        bit [7:0] x = 10;
        function int get_rand_x(input bit[7:0] x = 20);
           packet1 pkt = new();
           pkt.randomize with {x == x;}; // 此处根据就近原则,两个x都是packet1作用域下的x
           pkt.randomize with {x == local::x;}; // local::x 指函数作用域的x
           pkt.randomize with {x == local::this.x;}; //此处通过this获得到是packet2作用域下的x
           return pkt.x;
        endfunction
    endclass

    initial begin
        packet2 pkt = new();
        $display("pkt.get_rand_x() = %0d",pkt.get_rand_x(30));
        
    end
endmodule














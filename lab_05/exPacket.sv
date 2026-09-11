class Packet;
    integer  i = 1;
    function new(int val);
        i = val;
    endfunction
    function shift();
        i = i << 1;
    endfunction
endclass 

class linkedpacked extends packet;
    integer i = 3; // 子域中的i，不会覆盖父类中的i

    function new();
        super.new(3);
        i = 4;
    endfunction

    function shift();
        i = i << 2;
    endfunction

endclass

module tb;
    initial begin
        // packet p = new(1);
        packet p = new(1);
        // linkedpacked lp = new(3);
        linkedpacked lp = new();
        packet tmp;
        tmp = lp;
        $display("p.i = %d", p.i);
        $display("lp.i = %d", lp.i);
        lp.shift();
        $display("lp.i = %d", lp.i);
        p.shift();
        $display("p.i = %d", lp.i);
    end
endmodule








 
class packet_c;
    integer command;
    static integer data = 5;
    packet_c prv;
    local id;
    function new(integer inival = 0);
        command = inival;
    endfunction
endclass

module packet_m;
    integer commmand;
endmodule

typedef struct{
    integer command;
}packet_s;

module tb;
    packet_m m1();
    packet_m m2();
    packet_s s1 = '{1};
    packet_c c1 = new();
    initial begin : ini_proc
        automatic packet_s s2 = '{2};
        automatic packet_c c2 = new();
    end
endmodule

module tb2;
    initial begin
        packet_c c1,c2;
        for (int i = 0; i < 10; i++) begin
            c1 = new(i);
            c2 = new(++i);
            $display("c1.command = %d", c1.command);
        end
    end
endmodule

module tb3;
    packet_c c1,c2;
    initial begin
        $display("c1.data = %d", c1.data);
        $display("c2.data = %d", c2.data);
        c1 = new(10);
        $display("c1.command = %d", c1.command);
        c2 = c1;
        $display("c2.command = %d", c2.command);
    end
endmodule

module tb4;
    packet_c linked_list1[$],linked_list2[$];
    initial begin
        packet_c cur,anobj;
        for(int i = 0 ; i < 10;i++) begin
            cur = new(i);
            if(linked_list1.size() > 0)
                cur.prv = linked_list1[$];
            linked_list1.push_back(cur);
            anobj = new cur;
            linked_list2.push_back(anobj);
        end
    end
endmodule


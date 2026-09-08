module tb;
    logic [31:0] vec1,vec2;
    initial begin
        vec1 = 'h11223344;
        vec2 = {8'h11,8'h22,8'h33,8'h44};
        $display("vec1=%h,vec2=%h",vec1,vec2);
    end
endmodule

module tb2;
    initial begin
       int dyn[] = '{10,11,12,13,14};
       $display("dyn contents: %p",dyn); 
       dyn.delete();
       $display("dyn contents after delete: %p",dyn);
    end
endmodule

module tb3;
    initial begin
        int q1[$] = '{1,2,3};
        int q2[$] = '{4};
        q1.insert(1,4);
        $display("q1 contents: %p",q1);
        q1 = {q1[0] , q2 , q1[1:$]};
        $display("q1 contents after insert and merge: %p",q1);
    end
endmodule

module tb4;
    initial begin
        bit [31:0] mem[ int unsigned];
        int unsigned data,addr;
        repeat(10) begin
            std::randomize(addr,data) with {addr[31:8] == 0; addr[1:0] ==0 ;data inside {[1:10]};};
            $display("addr=%d,data=%d",addr,data);
            mem[addr] = data;
            foreach(mem[i]) begin
                $display("mem[%d]=%d",i,mem[i]);
            end
        end
        if(mem.first(addr)) begin
            do
                $display("mem[%d]=%d",addr,mem[addr]);
            while(mem.next(addr));
        end
        if(mem.exists('h10)) 
            $display("mem[10] exists : %d",mem['h10]);
        else
            $display("mem[10] does not exist");
    end
endmodule

module tb5;
    initial begin
        int dyn1[] = '{1,1,2,3,4,5,6};
        int quel[$] = '{1,2,3,4,5,6};

        int tq[$];
        tq = q.min();
        $display("Minimum value in quel: %d",tq[0]);
        tq = d.max();
        $display("Maximum value in dyn1: %d",tq[0]);
        tq = dyn1.unique();
        $display("Unique values in dyn1: %p",tq);
        int d[] = '{4,5,8,9,3,6};
        tq = d.sort();
        $display("Sorted values in d: %p",tq);
    end
endmodule

module tb6;
    initial begin
        int arr [4:0];
        int dyn = '{1,1,1,1,5};
        $display("arr contents: %d",$size(arr,1));
        $display("dyn contents: %d",$size(dyn,1));
    end
endmodule





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


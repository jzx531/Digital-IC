module tb;
    logic [31:0] vec1,vec2;
    initial begin
        vec1 = 'h11223344;
        vec2 = {8'h11,8'h22,8'h33,8'h44};
        $display("vec1=%h,vec2=%h",vec1,vec2);
    end
endmodule



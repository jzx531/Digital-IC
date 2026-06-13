module counter(out, clk, enable,reset);
output[7:0]  out; 
input clk, reset, enable;
reg[7:0] out;
always @ (posedge clk) begin
    if(reset) begin
        out <= 8'b0;
    end else if(enable) begin
        out <= out + 1;
    end
end
endmodule

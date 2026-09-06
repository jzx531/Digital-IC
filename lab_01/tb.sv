module rt_stimulator(
  input clock,
  input reset_n,
  output [15:0] din,
  output [15:0] frame_n,
  input [15:0] valid_n,
  input [15:0] dout,
  input [15:0] valido_n,
  input [15:0] busy_n,
  input [15:0] frameo_n
);
endmodule

module rt_test_top;
end


module tb;

reg clk;
reg rstn;

logic [15:0] din, frame_n, valid_n;

logic [15:0] dout, valido_n, busy_n, frameo_n;
 
//generate clock
initial 
  forever #5ns clk<=~clk;

//generate reset
initial begin
  #2ns rstn<=1;
  #10ns rstn <= 0;
  #10ns rstn<=1;
end

router dut(
  .reset_n(rstn),
  .clock(clk)
);

endmodule

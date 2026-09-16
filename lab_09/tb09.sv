interface rt_interface;
  logic clock;
  logic reset_n;
  logic [15:0] din;
  logic [15:0] frame_n;
  logic [15:0] valid_n;
  logic [15:0] dout;
  logic [15:0] valido_n;
  logic [15:0] busy_n;
  logic [15:0] frameo_n;

  // stimulus side: drives inputs, observes outputs
  modport stim (
    input  clock, reset_n,
    input  dout, valido_n, busy_n, frameo_n,
    output din, frame_n, valid_n
  );

  // router side (reference; router is instantiated with scalar pins)
  modport dut (
    input  clock, reset_n,
    input  din, frame_n, valid_n,
    output dout, valido_n, busy_n, frameo_n
  );

  modport mon (
    input clock, reset_n,
    input din, frame_n, valid_n,
    input dout, valido_n, busy_n, frameo_n
  );

  // covergroup rt_src_chnl_parallel_proc () with function
  covergroup rt_src_two_chnl_parallel_proc @(posedge clock iff $countones(valid_n) <=(16-2));
   // coverpoint din {
    PARA: coverpoint valid_n{
      wildcard bins ch0 = {16'bxxxx_xxxx_xxxx_xxx0};
      wildcard bins ch1 = {16'bxxxx_xxxx_xxxx_xx0x};
      wildcard bins ch2 = {16'bxxxx_xxxx_xxxx_x0xx};
      wildcard bins ch3 = {16'bxxxx_xxxx_xxxx_0xxx};
      wildcard bins ch4 = {16'bxxxx_xxxx_xxx0_xxxx};
      wildcard bins ch5 = {16'bxxxx_xxxx_xx0x_xxxx};
      wildcard bins ch6 = {16'bxxxx_xxxx_x0xx_xxxx};
      wildcard bins ch7 = {16'bxxxx_xxxx_0xxx_xxxx};
      wildcard bins ch8 = {16'bxxxx_xxx0_xxxx_xxxx};
      wildcard bins ch9  = {16'bxxxx_xx0x_xxxx_xxxx};
      wildcard bins ch10 = {16'bxxxx_x0xx_xxxx_xxxx};
      wildcard bins ch11 = {16'bxxxx_0xxx_xxxx_xxxx};
      wildcard bins ch12 = {16'bxxx0_xxxx_xxxx_xxxx};
      wildcard bins ch13 = {16'bxx0x_xxxx_xxxx_xxxx};
      wildcard bins ch14 = {16'bx0xx_xxxx_xxxx_xxxx};
      wildcard bins ch15 = {16'b0xxx_xxxx_xxxx_xxxx};
    }
  endgroup

  covergroup rt_dest_two_chnl_parallel_proc@(posedge clock iff $countones(valido_n) <=(16-2));
   // coverpoint din {
    PARA: coverpoint valido_n{
      wildcard bins ch0 = {16'bxxxx_xxxx_xxxx_xxx0};
      wildcard bins ch1 = {16'bxxxx_xxxx_xxxx_xx0x};
      wildcard bins ch2 = {16'bxxxx_xxxx_xxxx_x0xx};
      wildcard bins ch3 = {16'bxxxx_xxxx_xxxx_0xxx};
      wildcard bins ch4 = {16'bxxxx_xxxx_xxx0_xxxx};
      wildcard bins ch5 = {16'bxxxx_xxxx_xx0x_xxxx};
      wildcard bins ch6 = {16'bxxxx_xxxx_x0xx_xxxx};
      wildcard bins ch7 = {16'bxxxx_xxxx_0xxx_xxxx};
      wildcard bins ch8 = {16'bxxxx_xxx0_xxxx_xxxx};
      wildcard bins ch9  = {16'bxxxx_xx0x_xxxx_xxxx};
      wildcard bins ch10 = {16'bxxxx_x0xx_xxxx_xxxx};
      wildcard bins ch11 = {16'bxxxx_0xxx_xxxx_xxxx};
      wildcard bins ch12 = {16'bxxx0_xxxx_xxxx_xxxx};
      wildcard bins ch13 = {16'bxx0x_xxxx_xxxx_xxxx};
      wildcard bins ch14 = {16'bx0xx_xxxx_xxxx_xxxx};
      wildcard bins ch15 = {16'b0xxx_xxxx_xxxx_xxxx};
    }
  endgroup

  initial begin
    rt_src_two_chnl_parallel_proc rt_src_cg;
    rt_dest_two_chnl_parallel_proc rt_dest_cg;

    rt_src_cg = new();
    rt_dest_cg = new();
    // rt_src_cg.sample();
    // rt_dest_cg.sample();
  end
endinterface


module rt_test_top;
endmodule


module tb;

import rt_multi_pkg::*; // import package

logic clk, rstn;

//generate clock
initial begin
  clk <= 0;
  forever #5ns clk<=~clk;
end

//generate reset
initial begin : rst_proc
  #2ns rstn<=1;
  #10ns rstn <= 0;
  #10ns rstn<=1;
end



rt_interface intf();
assign intf.clock = clk;
assign intf.reset_n = rstn;

router dut(
  .reset_n(intf.reset_n),
  .clock(intf.clock),
  .din(intf.din),
  .frame_n(intf.frame_n),
  .valid_n(intf.valid_n),
  .dout(intf.dout),
  .valido_n(intf.valido_n),
  .busy_n(intf.busy_n),
  .frameo_n(intf.frameo_n)
);

// 例化
rt_stimulator stim;

rt_monitor mon;

rt_generator gen;

rt_checker chk;


rt_single_ch_test single_ch_test;
rt_multi_ch_test multi_ch_test;
rt_two_ch_test two_ch_test;
rt_two_ch_same_chnout_test two_ch_same_chnout_test;

rt_base_test tests[string];
initial begin : inst_init_proc
  string name;
  single_ch_test = new(intf);
  multi_ch_test = new(intf);
  two_ch_test = new(intf);
  two_ch_same_chnout_test = new(intf);

  tests["single_ch_test"] = single_ch_test;
  tests["multi_ch_test"] = multi_ch_test;
  tests["two_ch_test"] = two_ch_test;
  tests["two_ch_same_chnout_test"] = two_ch_same_chnout_test;

  if($value$plusargs("TESTNAME=%s",name)) begin
    if(tests.exists(name)) begin
      if(tests.exists(name)) begin
        tests[name].run();
      end
      else begin
        $display("Test name %s not found",name); // if test name not found, print error message
      end
    end
    else begin
      $display("Test name %s not found",name); // if test name not found, print error message
    end
  end
  else begin
    // $fatal("No test name specified");
    tests["single_ch_test"].run();
    // multi_ch_test.run();
  end

end


endmodule

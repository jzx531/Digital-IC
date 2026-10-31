`timescale 1ns/1ps

module mcdt_tb;
  import mcdt_tb_pkg::*;

  logic clk;
  logic rstn;

  mcdt_chnl_intf ch0_if(clk, rstn);
  mcdt_chnl_intf ch1_if(clk, rstn);
  mcdt_chnl_intf ch2_if(clk, rstn);
  mcdt_out_intf  out_if(clk, rstn);

  mcdt dut (
    .clk_i        (clk),
    .rstn_i       (rstn),
    .ch0_data_i   (ch0_if.ch_data),
    .ch0_valid_i  (ch0_if.ch_valid),
    .ch0_ready_o  (ch0_if.ch_ready),
    .ch0_margin_o (ch0_if.ch_margin),
    .ch1_data_i   (ch1_if.ch_data),
    .ch1_valid_i  (ch1_if.ch_valid),
    .ch1_ready_o  (ch1_if.ch_ready),
    .ch1_margin_o (ch1_if.ch_margin),
    .ch2_data_i   (ch2_if.ch_data),
    .ch2_valid_i  (ch2_if.ch_valid),
    .ch2_ready_o  (ch2_if.ch_ready),
    .ch2_margin_o (ch2_if.ch_margin),
    .mcdt_data_o  (out_if.mcdt_data),
    .mcdt_val_o   (out_if.mcdt_val),
    .mcdt_id_o    (out_if.mcdt_id)
  );

  initial begin
    clk = 1'b0;
    forever #5ns clk = ~clk;
  end

  initial begin
    rstn = 1'b0;
    ch0_if.ch_data  = 32'b0;
    ch0_if.ch_valid = 1'b0;
    ch1_if.ch_data  = 32'b0;
    ch1_if.ch_valid = 1'b0;
    ch2_if.ch_data  = 32'b0;
    ch2_if.ch_valid = 1'b0;
    repeat (10) @(posedge clk);
    rstn <= 1'b1;
  end

  initial begin
    mcdt_basic_test test;
    test = new();
    test.set_interface(ch0_if, ch1_if, ch2_if, out_if);
    test.run();
  end

  initial begin
    #20ms;
    $fatal(1, "[GLOBAL TIMEOUT] simulation exceeded 20 ms");
  end
endmodule

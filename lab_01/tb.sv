module rt_stimulator(
  input clock,
  input reset_n,
  output reg [15:0] din,
  output reg [15:0] frame_n,
  output reg [15:0] valid_n,
  input [15:0] dout,
  input [15:0] valido_n,
  input [15:0] busy_n,
  input [15:0] frameo_n
);

  initial begin:drive_reset_proc
    @(negedge reset_n);
    din <= 0;
    frame_n <= 1;
    valid_n <= 1;
  end

  // drive channel0 - channel 15（din[0:15)）]
  bit [3:0] addr;
  byte unsigned data[];
  initial begin : drive_chn10_proc
    @(negedge reset_n);
    repeat(10) @(posedge clock);
    addr = 3;
    data = '{8'h33,8'h77};
    //drive address phase
    for (int i = 0; i < 4; i++) begin
      @(posedge clock);
      din[0] <= addr[i];
      valid_n[0] <= 1'b0; // TODO: check valid bit 0/1 later
      frame_n[0] <= 1'b0;
    end
    //drive data phase
    for(int i = 0; i < 4; i++) begin
      @(posedge clock);
      din[0] <= 1;
      valid_n[0] <= 1'b0; // TODO: check valid bit 0/1 later
      frame_n[0] <= 1'b0;
    end

    //drive data phase
    foreach(data[id]) begin
      for(int i = 0; i < 8; i++) begin
        @(posedge clock);
        din[0] <= data[id][i];
        valid_n[0] <= 1'b0; // TODO: check valid bit 0/1 later
        if(id == data.size()-1 && i == 7) begin
          frame_n[0] <= 1'b1;
        end else begin
          frame_n[0] <= 1'b0;
        end

        // frame_n[0] <= (id == data.size()-1 && i == 7)? 1'b1 : 1'b0; // TODO: check valid bit 0/1 later
      end
    end

    //drive idle phase
    @(posedge clock);
    din[0]<=0;
    valid_n[0] <= 1'b1;
    frame_n[0] <= 1'b1;
  end

endmodule

module rt_test_top;
endmodule


module tb;

logic clk, rstn;

logic [15:0] din, frame_n, valid_n;

logic [15:0] dout, valido_n, busy_n, frameo_n;
 
//generate clock
initial begin
  clk <= 0;
  forever #5ns clk<=~clk;
end

//generate reset
initial begin
  #2ns rstn<=1;
  #10ns rstn <= 0;
//  #10ns rstn<=1;
end

// router dut(
//   .reset_n(rstn),
//   .clock(clk),
//   .din(din),
//   .frame_n(frame_n),
//   .valid_n(valid_n),
//   .dout(dout),
//   .valido_n(valido_n),
//   .busy_n(busy_n),
//   .frameo_n(frameo_n)
// );

router dut(
  .reset_n(rstn),
  .clock(clk),
  .*
);

rt_stimulator stim(
  .clock(clk),
  .reset_n(rstn),
  .*
);

endmodule

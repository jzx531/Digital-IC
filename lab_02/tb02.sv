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
//for debug purpose from waveform
 typedef enum {DRV_RESET,DRV_IDLE,DRV_ADDR,DRV_PAD,DRV_DATA} drv_state_t;
 drv_state_t state;

  // initial begin:drive_reset_proc
 task drive_reset;
    @(negedge reset_n);
    state <= DRV_RESET;
    din <= 0;
    frame_n <= '1;
    valid_n <= '1;
 endtask
  // end

  // drive channel0 - channel 15（din[0:15)）]
  bit [3:0] addr;
  byte unsigned data[];
  //  initial begin : drive_chn10_proc
  task drive_chn10(bit[3:0] saddr,bit[3:0] daddr,byte unsigned data[]);
    @(negedge reset_n);
    repeat(10) @(posedge clock);

    // addr = 4'd3;
    // data = '{8'h33,8'h77};

    //drive address phase
    for (int i = 0; i < 4; i++) begin
      @(posedge clock);
      state<= DRV_ADDR;
      din[saddr] <= daddr[i];
      valid_n[saddr] <= 1'b1; // TODO: check valid bit 0/1 later
      frame_n[saddr] <= 1'b0;
    end
    //drive data phase
    for(int i = 0; i < 4; i++) begin
      @(posedge clock);
      state <= DRV_PAD;
      din[saddr] <= 1;
      valid_n[saddr] <= 1'b1; // TODO: check valid bit 0/1 later
      frame_n[saddr] <= 1'b0;
    end

    //drive data phase
    foreach(data[id]) begin
      for(int i = 0; i < 8; i++) begin
        @(posedge clock);
        state <= DRV_DATA;
        din[saddr] <= data[id][i];
        valid_n[saddr] <= 1'b0; // TODO: check valid bit 0/1 later
        if(id == data.size()-1 && i == 7) begin
          frame_n[saddr] <= 1'b1;
        end else begin
          frame_n[saddr] <= 1'b0;
        end

        // frame_n[0] <= (id == data.size()-1 && i == 7)? 1'b1 : 1'b0; // TODO: check valid bit 0/1 later
      end
    end

    //drive idle phase
    @(posedge clock);
    state <= DRV_IDLE;
    din[0]<=0;
    valid_n[0] <= 1'b1;
    frame_n[0] <= 1'b1;
  endtask
  // end

  initial begin:drive_reset_proc;
    drive_reset();
  end

  initial begin:drive__proc;
    // drive_chn10(.addr(3),.data({8'h33,8'h77}));
    drive_chn10(1,3,'{8'h33,8'h77});
    $display("chnl3 completed");
    drive_chn10(4,6,'{8'h44,8'h55});
    $display("chnl2 completed");
    drive_chn10(7,9,'{8'h55,8'h66});
    $display("chnl4 completed");
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
  #10ns rstn<=1;
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

typedef struct{
  bit [3:0] src;
  bit [3:0] dst;
  bit [7:0] data[];
}rt_packet_t;

module rt_generator;
  rt_packet_t pkts[$];

  // task gen_pkts(bit [3:0] src , bit [3:0] dst,bit[7:0] data[]);
  task gen_pkts(rt_packet_t p);
    pkts.push_back(p);
  endtask

  function void put_pkt(rt_packet_t p);
    pkts.push_back(p);
  endfunction

  /*
  function rt_packet_t get_pkt();
    if(pkts.size() > 0)
      return pkts.pop_front();
    else begin
      $display("No packet available");
      return '{src:0,dst:0,data:'{}};
    end
  endfunction
 

  function bit get_pkt(output rt_packet_t p);
    if(pkts.size() > 0) begin
      p = pkts.pop_front();
      return 1;
    end
    else begin
      $display("No packet available");
      return 0;
    end
  endfunction 
    */

  task get_pkt(output rt_packet_t p);
    wait(pkts.size() > 0)
      p = pkts.pop_front();
  endtask

  function void gen_pkt(int src = -1, int dst = -1);
  endfunction

endmodule

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

 rt_packet_t pkt[$];

  function void put_pkt(rt_packet_t p);
    pkt.push_back(p);
  endfunction

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

  bit [1:0] drv_done;
  //  initial begin : drive_chn10_proc
  task automatic drive_chn1(bit[3:0] saddr,bit[3:0] daddr,byte unsigned data[]);
    // addr = 4'd3;
    // data = '{8'h33,8'h77};

    $display("chnl%d started addr = %d", saddr, daddr);
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

    $display("chnl%d started addr = %d", saddr, daddr);
  endtask
  // end

  initial begin:drive_reset_proc;
    drive_reset();
  end

  // stop simulation as soon as both drive processes have completed
  always @(drv_done) begin
    if (drv_done == 2'b11) $finish;
  end

  rt_packet_t p;
  initial begin:drive_chnl0_proc;
    // drive_chn10(.addr(3),.data({8'h33,8'h77}));
    
    @(negedge reset_n);
    repeat(10) @(posedge clock);

    forever begin
      wait(pkt.size() > 0);
      p = pkt.pop_front();
      drive_chn1(p.src,p.dst,p.data);
    end

    // drive_chn1(0,3,'{8'h33,8'h77});
    // $display("chnl0 completed");
    // drive_chn1(0,6,'{8'h44,8'h55});
    // $display("chnl2 completed");
    drv_done[0] = 1'b1;
  end

  /*
  initial begin:drive_chnl1_proc;
    // drive_chn10(.addr(3),.data({8'h33,8'h77}));
    @(negedge reset_n);
    repeat(10) @(posedge clock);
    drive_chn1(1,5,'{8'h33,8'h77,8'h88});
    $display("chnl1 completed");
    drv_done[1] = 1'b1;
  end
    */

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

rt_generator gen();

//generate and transmit packet
initial begin : generate_proc
  rt_packet_t p ;
  p = '{src:0,dst:1,data:{8'h33,8'h77,8'h88}};
  gen.put_pkt(p);
  gen.put_pkt('{src:0,dst:2,data:{8'h44,8'h55}});
end

initial begin : transmit_proc
  rt_packet_t p;
  forever begin
     gen.get_pkt(p);
     stim.put_pkt(p);
  end
end

endmodule

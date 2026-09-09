typedef struct{
  bit [3:0] src;
  bit [3:0] dst;
  bit [7:0] data[];
}rt_packet_t;

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
endinterface

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
  /*
  input clock,
  input reset_n,
  output reg [15:0] din,
  output reg [15:0] frame_n,
  output reg [15:0] valid_n,
  input [15:0] dout,
  input [15:0] valido_n,
  input [15:0] busy_n,
  input [15:0] frameo_n
  */
  rt_interface.stim intf
);
//for debug purpose from waveform
 typedef enum {DRV_RESET,DRV_IDLE,DRV_ADDR,DRV_PAD,DRV_DATA} drv_state_t;
 drv_state_t state;

 rt_packet_t pkt[$];
 int src_chnl_status [int];

  function void put_pkt(rt_packet_t p);
    pkt.push_back(p);
  endfunction

  // initial begin:drive_reset_proc
 task drive_reset;
    @(negedge intf.reset_n);
    state <= DRV_RESET;
    intf.din <= 0;
    intf.frame_n <= '1;
    intf.valid_n <= '1;
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
      @(posedge intf.clock);
      state<= DRV_ADDR;
      intf.din[saddr] <= daddr[i];
      intf.valid_n[saddr] <= 1'b1; // TODO: check valid bit 0/1 later
      intf.frame_n[saddr] <= 1'b0;
    end
    //drive data phase
    for(int i = 0; i < 4; i++) begin
      @(posedge intf.clock);
      state <= DRV_PAD;
      intf.din[saddr] <= 1;
      intf.valid_n[saddr] <= 1'b1; // TODO: check valid bit 0/1 later
      intf.frame_n[saddr] <= 1'b0;
    end

    //drive data phase
    foreach(data[id]) begin
      for(int i = 0; i < 8; i++) begin
        @(posedge intf.clock);
        state <= DRV_DATA;
        intf.din[saddr] <= data[id][i];
        intf.valid_n[saddr] <= 1'b0; // TODO: check valid bit 0/1 later
        if(id == data.size()-1 && i == 7) begin
          intf.frame_n[saddr] <= 1'b1;
        end else begin
          intf.frame_n[saddr] <= 1'b0;
        end

        // frame_n[0] <= (id == data.size()-1 && i == 7)? 1'b1 : 1'b0; // TODO: check valid bit 0/1 later
      end
    end

    //drive idle phase
    @(posedge intf.clock);
    state <= DRV_IDLE;
    intf.din[0]<=0;
    intf.valid_n[0] <= 1'b1;
    intf.frame_n[0] <= 1'b1;

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

  // rt_packet_t p;
  initial begin:drive_chnl0_proc;
    // drive_chn10(.addr(3),.data({8'h33,8'h77}));
    
    @(negedge intf.reset_n);
    repeat(10) @(posedge intf.clock);

    forever begin
      automatic rt_packet_t pf;
      wait(pkt.size() > 0);
      pf = pkt.pop_front();
      
      fork begin
        // automatic rt_packet_t pf = p;
          wait_src_chnl_avail(pf);
          drive_chn1(pf.src,pf.dst,pf.data);
          set_src_chnl_avail(pf);
        end
      join_none
    end
    drv_done[0] = 1'b1;
  end

    task automatic wait_src_chnl_avail(rt_packet_t p);
      if(!src_chnl_status.exists(p.src))
        src_chnl_status[p.src] = p.dst;
      else if(src_chnl_status[p.src] >= 0)
        wait(src_chnl_status[p.src] == -1);
    endtask

    function automatic set_src_chnl_avail(rt_packet_t p);
      src_chnl_status[p.src] = -1;
    endfunction
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

rt_stimulator stim(
  intf
);

rt_generator gen();

//generate and transmit packet
initial begin : generate_proc
  rt_packet_t p ;
  p = '{src:0,dst:1,data:{8'h33,8'h77,8'h88}};
  gen.put_pkt(p);
  gen.put_pkt('{src:0,dst:2,data:{8'h44,8'h55}});
  gen.put_pkt('{src:4,dst:7,data:{8'h66,8'h99}});
end

initial begin : transmit_proc
  rt_packet_t p;
  forever begin
     gen.get_pkt(p);
     stim.put_pkt(p);
  end
end

endmodule


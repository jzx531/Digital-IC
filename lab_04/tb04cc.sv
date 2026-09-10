// typedef struct{
class rt_packet;
  bit [3:0] src;
  bit [3:0] dst;
  bit [7:0] data[];

  function new(); endfunction
  function void set_members(bit [3:0] src, bit [3:0] dst, bit [7:0] data[]);
    this.src = src;
    this.dst = dst;
    this.data = new[data.size()];
    foreach (data[i]) begin
      this.data[i] = data[i];
    end
  endfunction

  function string sprint();
    sprint = "";
    sprint = {sprint, $sformatf("src = %0d \n", src)};
    sprint = {sprint, $sformatf("dst = %0d \n", dst)};
    sprint = {sprint, $sformatf("data length = %0d \n", data.size())};
    foreach (data[i]) begin
      sprint = {sprint, $sformatf("data[%0d] = %0d \n", i, this.data[i])};
    end
  endfunction

  function bit compare(rt_packet p);
    compare = 1'b0;
    if (p == null) begin
      return compare;
    end
    if (src != p.src || dst != p.dst || data.size() != p.data.size()) begin
      return compare;
    end
    foreach (data[i]) begin
      if (data[i] != p.data[i]) begin
        return compare;
      end
    end
    compare = 1'b1;
  endfunction
endclass
// }rt_packet;

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
endinterface

class rt_generator;
  rt_packet pkts[$];

  // task gen_pkts(bit [3:0] src , bit [3:0] dst,bit[7:0] data[]);
  task gen_pkts(rt_packet p);
    pkts.push_back(p);
  endtask

  function void put_pkt(rt_packet p);
    pkts.push_back(p);
  endfunction



  task get_pkt(output rt_packet p);
    wait(pkts.size() > 0)
      p = pkts.pop_front();
  endtask

  function void gen_pkt(int src = -1, int dst = -1);
  endfunction

  task run();
    // TODO: generate packets
  endtask

endclass

// module rt_stimulator(
class rt_stimulator;

  virtual rt_interface.stim intf;
//for debug purpose from waveform
 typedef enum {DRV_RESET,DRV_IDLE,DRV_ADDR,DRV_PAD,DRV_DATA} drv_state_t;
 drv_state_t state;

 rt_packet pkt[$];
 int src_chnl_status [int];

  function void put_pkt(rt_packet p);
    pkt.push_back(p);
  endfunction

  // initial begin:drive_reset_proc
 task drive_reset;
  forever begin
      @(negedge intf.reset_n);
      state <= DRV_RESET;
      intf.din <= 0;
      intf.frame_n <= '1;
      intf.valid_n <= '1;
  end
 endtask
  // end

  // drive channel0 - channel 15（din[0:15)）]
  bit [3:0] addr;
  byte unsigned data[];

  bit [1:0] drv_done;
  //  initial begin : drive_chn10_proc
  // task automatic drive_chn1(bit[3:0] saddr,bit[3:0] daddr,byte unsigned data[]);
  task automatic drive_chn1_proc(rt_packet p);
    // addr = 4'd3;
    // data = '{8'h33,8'h77};

    $display("chnl%d started addr = %d", p.src, p.dst);
    //drive address phase
    for (int i = 0; i < 4; i++) begin
      @(posedge intf.clock);
      state<= DRV_ADDR;
      intf.din[p.src] <= p.dst[i];
      intf.valid_n[p.src] <= 1'b1; // TODO: check valid bit 0/1 later
      intf.frame_n[p.src] <= 1'b0;
    end
    //drive data phase
    for(int i = 0; i < 4; i++) begin
      @(posedge intf.clock);
      state <= DRV_PAD;
      intf.din[p.src] <= 1;
      intf.valid_n[p.src] <= 1'b1; // TODO: check valid bit 0/1 later
      intf.frame_n[p.src] <= 1'b0;
    end

    //drive data phase
    for (int id = 0; id < p.data.size(); id++) begin
      for(int i = 0; i < 8; i++) begin
        @(posedge intf.clock);
        state <= DRV_DATA;
        intf.din[p.src] <= p.data[id][i];
        intf.valid_n[p.src] <= 1'b0; // TODO: check valid bit 0/1 later
        if(id == p.data.size()-1 && i == 7) begin
          intf.frame_n[p.src] <= 1'b1;
        end else begin
          intf.frame_n[p.src] <= 1'b0;
        end

        // frame_n[0] <= (id == data.size()-1 && i == 7)? 1'b1 : 1'b0; // TODO: check valid bit 0/1 later
      end
    end

    //drive idle phase
    @(posedge intf.clock);
    state <= DRV_IDLE;
    intf.din[p.src] <= 1'b0;
    intf.valid_n[p.src] <= 1'b1;
    intf.frame_n[p.src] <= 1'b1;

    $display("chnl%d completed addr = %d", p.src, p.dst);
  endtask
  // end

task run();
  fork
    drive_reset();
    drive_chnl();
  join_none
endtask



  // rt_packet p;
task drive_chnl();
    
    @(negedge intf.reset_n);
    repeat(10) @(posedge intf.clock);

    forever begin
      automatic rt_packet pf;
      wait(pkt.size() > 0);
      pf = pkt.pop_front();
      
      fork begin
        // automatic rt_packet pf = p;
          wait_src_chnl_avail(pf);
          // drive_chn1(pf.src,pf.dst,pf.data);
          drive_chn1_proc(pf);
          // wait_src_chnl_avail(pf);
          set_src_chnl_avail(pf);
        end
      join_none
    end
    drv_done[0] = 1'b1;
  endtask

    task automatic wait_src_chnl_avail(rt_packet p);
      if(!src_chnl_status.exists(p.src))
        src_chnl_status[p.src] = p.dst;
      else if(src_chnl_status[p.src] >= 0)
        wait(src_chnl_status[p.src] == -1);
    endtask

    task automatic set_src_chnl_avail(rt_packet p);
      src_chnl_status[p.src] = -1;
    endtask

endclass
// endmodule

class rt_monitor;
  virtual rt_interface.mon intf;

  rt_packet in_pkts[16][$];
  rt_packet out_pkts[16][$];

  task mon_chnls;
    foreach(in_pkts[i]) begin
      automatic int chid = i;
      fork
        mon_chnl_in(chid);
        mon_chnl_Out(chid);
      join_none
    end
  endtask

  task run();
    fork
      mon_chnls();
    join_none
  endtask

  task  mon_chnl_in(bit [3:0] schid);
    automatic rt_packet pkt;
    forever begin
      // clear content for the same struct variable
      pkt = new();
      // pkt.data.delete();
      pkt.src = schid;
      // monitor specific channel-in data and put it into the queue
      @(negedge intf.frame_n[schid]);
      for(int i = 0; i < 4; i++) begin
        @(negedge intf.clock);
        pkt.dst[i] = intf.din[schid];
      end
      // pass pad phase
      repeat(4) @(negedge intf.clock);
      // monitor data phase
      do begin
        pkt.data =  new[pkt.data.size() + 1] (pkt.data);
        for(int i = 0; i < 8 ; i++) begin
          @(negedge intf.clock);
          pkt.data[pkt.data.size() - 1][i] = intf.din[schid];
        end
      end while(!intf.frame_n[schid]);
      in_pkts[schid].push_back(pkt);
      $display("[Monitor] chnl_in in_pkt[%d] = %p trans finished", schid, pkt);
    end
  endtask

    
    task   mon_chnl_Out(bit [3:0] schid);
  // monitor specific channel-out data and put it into the queue
    automatic rt_packet pkt;
    forever begin
      pkt = new();
      // pkt.data.delete();
      pkt.src = 0;
      pkt.dst = schid;
      @(negedge intf.frameo_n[schid]);
      do begin
        pkt.data = new [pkt.data.size() + 1](pkt.data);
        for(int i = 0; i < 8; i++) begin
          @(negedge intf.clock iff !intf.valido_n[schid]);
          pkt.data[pkt.data.size() - 1][i] = intf.dout[schid];
        end
      end while(!intf.frameo_n[schid]);
      out_pkts[schid].push_back(pkt);
      $display("[Monitor] chnl_out out_pkt[%d] = %p trans finished", schid, pkt);
    end
  endtask

endclass


class rt_checker;

int unsigned compare_count;
int unsigned error_count;

  rt_packet exp_out_pkts[16][$];
  rt_monitor mon;

  task run();
  // TODO: check packets
    foreach(exp_out_pkts[i]) begin
      automatic int id = i;
      fork
        do_routing(id);
        do_compare(id);
      join_none
    end
  endtask

  task do_routing(bit [3:0] id);
  // do routing
    rt_packet pkt;
    forever begin
      wait(mon.in_pkts[id].size() > 0);
      pkt = mon.in_pkts[id].pop_front();
      exp_out_pkts[pkt.dst].push_back(pkt);
    end
  endtask

  task do_compare(bit [3:0] id);
    rt_packet exp_pkt;
    rt_packet out_pkt;
    forever begin
      wait(mon.out_pkts[id].size() > 0 && exp_out_pkts[id].size() > 0);
      out_pkt = mon.out_pkts[id].pop_front();
      exp_pkt = exp_out_pkts[id].pop_front();
      if(exp_pkt.compare(out_pkt)) begin
        $display("[Checker] chnl_out exp_pkt[%d] = %p == out_pkt[%d] = %p", id, exp_pkt, id, out_pkt);
      end else begin
        $display("[Checker] chnl_out exp_pkt[%d] = %p != out_pkt[%d] = %p", id, exp_pkt, id, out_pkt);
        error_count++;
      end
      compare_count++;
      if(compare_count >= 100) begin
        do_report();
        compare_count = 0;
        error_count = 0;
      end
    end
  endtask

  function void do_report();
    if(!error_count) begin
      $display("[Checker] no error found");
    end
    else begin
      $display("[Checker] total compare count = %d, error count = %d", compare_count, error_count);
    end
  endfunction

endclass

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

initial begin : inst_proc
  stim = new();
  gen = new();
  mon = new();
  chk = new();
  stim.intf = intf;
  mon.intf = intf;
  chk.mon = mon;
  fork 
    stim.run();
    gen.run();
    mon.run();
    chk.run();
  join_none
end


//generate and transmit packet
initial begin : generate_proc
  rt_packet p ;
  #0; // wait for test components instantiated
  // p/pkt 是 handle；new() 是创建新对象；每个 packet/transaction 要独立保存时，就必须重新 new()。
  p = new();
  p.set_members(0,1,'{8'h33,8'h77,8'h88});
  gen.put_pkt(p);
  p = new();
  p.set_members(0,2,'{8'h44,8'h55});
  gen.put_pkt(p);
  p = new();
  p.set_members(4,7,'{8'h66,8'h99});
  gen.put_pkt(p);
  // p = '{src:0,dst:1,data:{8'h33,8'h77,8'h88}};
  // gen.put_pkt(p);
  // gen.put_pkt('{src:0,dst:2,data:{8'h44,8'h55}});
  // gen.put_pkt('{src:4,dst:7,data:{8'h66,8'h99}});
end

initial begin : transmit_proc
  rt_packet p;
  #0; // wait for test components instantiated
  forever begin
     gen.get_pkt(p);
     stim.put_pkt(p);
  end
end

endmodule

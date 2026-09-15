// Compile this file instead of router_multi_pkg.sv; the package name is unchanged.
package rt_multi_pkg;
// typedef struct{
class rt_packet;
  rand bit [3:0] src;
  // randc cannot participate in soft constraints; each packet is a new object.
  rand bit [3:0] dst;
  rand bit [7:0] data[];
  constraint pkt_cstr{
    soft data.size() inside {[1:32]};
    foreach (data[i]) 
       soft data[i] == (src << 4) + i;
    // Defaults may be overridden by each test's inline constraints.
    soft src inside {[1:3]};
    soft dst inside {[5:7]};
    data.size() > 0;
    // The output monitor recovers the source from the first byte.
    data[0][7:4] == src;
  }

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

class rt_generator;
  // rt_packet pkts[$];
  mailbox #(rt_packet) pkts;
  int unsigned generated_count = 0;

  function new();
    pkts = new(1); // TODO: check if this is necessary
  endfunction

  // task gen_pkts(bit [3:0] src , bit [3:0] dst,bit[7:0] data[]);
  task gen_pkts(rt_packet p);
    pkts.put(p);
    generated_count++;
  endtask

  task put_pkt(rt_packet p);
    pkts.put(p);
    generated_count++;
  endtask

  task get_pkt(output rt_packet p);
    pkts.get(p);
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

//  rt_packet pkt[$];
 mailbox #(rt_packet) pkt;

 mailbox #(rt_packet) ch_pkts[16];

 semaphore src_chnl_status[16];
//  int src_chnl_status [int];

  function new();
    // pkt = new();
    foreach(src_chnl_status[i])
      src_chnl_status[i] = new(1);

    foreach(ch_pkts[i])
      ch_pkts[i] = new();

 endfunction


  task put_pkt(rt_packet p);
    // pkt.push_back(p);
    pkt.put(p);
  endtask

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
  task automatic drive_chnl_proc(rt_packet p);


    $display("chnl%d started addr = %d", p.src, p.dst);
    //drive address phase
    for (int i = 0; i < 4; i++) begin
      @(posedge intf.clock);
      state<= DRV_ADDR;
      intf.din[p.src] <= p.dst[i];
      intf.valid_n[p.src] <= 1'b1; // TODO: check valid bit 0/1 later
      intf.frame_n[p.src] <= 1'b0;
    end
    // Allow registered busy_n to reflect address decode before checking it.
    for(int i = 0; i < 5; i++) begin
      @(posedge intf.clock);
      state <= DRV_PAD;
      intf.din[p.src] <= 1;
      intf.valid_n[p.src] <= 1'b1; // TODO: check valid bit 0/1 later
      intf.frame_n[p.src] <= 1'b0;
    end

    // Sample after the DUT's posedge updates, while keeping the frame open.
    do begin
      @(negedge intf.clock);
    end while (intf.busy_n[p.src] !== 1'b1);

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
    // drive_chnl();
    distribute_packets();
    get_packet_and_drive();
  join_none
endtask

task distribute_packets();
  rt_packet p;
  forever begin
    pkt.get(p);
    ch_pkts[p.src].put(p);
  end
endtask

  // rt_packet p;
task drive_chnl();
    
    @(negedge intf.reset_n);
    repeat(10) @(posedge intf.clock);

    forever begin
      automatic rt_packet pf;
      // wait(pkt.size() > 0);
      // pf = pkt.pop_front();
      pkt.get(pf);
      
      fork begin
        // automatic rt_packet pf = p;
          wait_src_chnl_avail(pf);
          // drive_chn1(pf.src,pf.dst,pf.data);
          drive_chnl_proc(pf);
          // wait_src_chnl_avail(pf);
          set_src_chnl_avail(pf);
        end
      join_none
    end
    drv_done[0] = 1'b1;
  endtask

  task get_packet_and_drive();
    @(negedge intf.reset_n);
    repeat(10) @(posedge intf.clock);
    foreach(ch_pkts[i]) begin

      automatic rt_packet p;
      automatic int id = i;
      fork
        forever begin
          ch_pkts[id].get(p);   
          drive_chnl_proc(p);
        end
      join_none
    end

  endtask

    task automatic wait_src_chnl_avail(rt_packet p);

      src_chnl_status[p.src].get(1);
    endtask

    task automatic set_src_chnl_avail(rt_packet p);

      src_chnl_status[p.src].put(1);
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
          @(negedge intf.clock iff !intf.valid_n[schid]);
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
      // pkt.src = pkt.data[0]>>24;
      pkt.src = pkt.data[0]>>4;
      out_pkts[schid].push_back(pkt);
      $display("[Monitor] chnl_out out_pkt[%d] = %p trans finished", schid, pkt);
    end
  endtask

endclass


class rt_checker;

int unsigned compare_count = 0;
int unsigned error_count = 0;

  rt_packet exp_out_pkts[16][$];
  rt_monitor mon;
  // bit check_data_buffer; // check if data buffer is empty

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
    int match_index;
    forever begin
      wait(mon.out_pkts[id].size() > 0);
      out_pkt = mon.out_pkts[id][0];
      // Arbitration may reorder different sources, but not a single source.
      wait(exp_out_pkts[id].size() > 0 &&
           find_expected_index(id, out_pkt.src) >= 0);
      match_index = find_expected_index(id, out_pkt.src);
      out_pkt = mon.out_pkts[id].pop_front();
      exp_pkt = exp_out_pkts[id][match_index];
      exp_out_pkts[id].delete(match_index);
      if(exp_pkt.compare(out_pkt)) begin
        $display("[Checker] chnl_out exp_pkt[%d] = %p == out_pkt[%d] = %p", id, exp_pkt, id, out_pkt);
      end else begin
        $display("[Checker] chnl_out exp_pkt[%d] = %p != out_pkt[%d] = %p", id, exp_pkt, id, out_pkt);
        error_count++;
      end
      compare_count++;
    end
  endtask

  function int find_expected_index(bit [3:0] id, bit [3:0] src);
    for (int i = 0; i < exp_out_pkts[id].size(); i++) begin
      if (exp_out_pkts[id][i].src == src)
        return i;
    end
    return -1;
  endfunction

  function void do_report(string name = "rt_checker", int expected_count = -1);
    bit buffers_empty;
    buffers_empty = check_data_buffer();
    $display("[Checker] %s total compare count = %0d, error count = %0d",
             name, compare_count, error_count);
    if (!error_count && buffers_empty && compare_count > 0 &&
        (expected_count < 0 || compare_count == expected_count))
      $display("[Checker] %s no error found", name);
    else
      $display("[Checker] %s FAILED: mismatches, pending packets, or incomplete comparisons", name);
  endfunction

  function bit check_data_buffer();
     check_data_buffer = 1;
     foreach(exp_out_pkts[id]) begin
        if (mon.in_pkts[id].size() != 0) begin
          check_data_buffer = 0;
          $display("[Checker] chnl_in in_pkt[%0d] buffer is not empty (size = %0d)",
                   id, mon.in_pkts[id].size());
        end
        if(exp_out_pkts[id].size() != 0) begin
          check_data_buffer = 0; // if any data buffer is not empty, return false
          $display("[Checker] chnl_out exp_pkt[%d] data buffer is not empty(with size = %d)", id, exp_out_pkts[id].size()); // if any data buffer is not empty, return false
        end
        if(mon.out_pkts[id].size() != 0) begin
          check_data_buffer = 0; // if any data buffer is not empty, return false
          $display("[Checker] chnl_out out_pkt[%d] data buffer is not empty(with size = %d)", id, mon.out_pkts[id].size()); // if any data buffer is not empty, return false
        end
     end
  endfunction

endclass

class rt_env;
  rt_stimulator stim;
  rt_monitor mon;
  rt_generator gen;
  rt_checker chk;
  function new(virtual rt_interface intf);
  // build stage
    stim = new();
    gen = new();
    mon = new();
    chk = new();
  // connect stage
    stim.intf = intf;
    mon.intf = intf;
    chk.mon = mon;
    stim.pkt = gen.pkts;
  endfunction


  task run();
  // run stage
    fork 
      stim.run();
      gen.run();
      mon.run();
      chk.run();

      begin : transmit_proc
        // rt_packet p;
        // forever begin
        //   gen.get_pkt(p);
        //   stim.put_pkt(p);
        // end
        stim.pkt = gen.pkts;
      end
    join_none
    // if(chk.check_data_buffer()) begin
    //   $display("[Env] all data buffer is empty");
    //   $finish(); // terminate the current test
    // end
  endtask

  function void report(string name = "rt_env");
  //report stage
  //TODO: report stage
    chk.do_report(name, gen.generated_count);
  endfunction

// report stage

endclass

class rt_base_test;
  rt_env env;
  bit gen_trans_done = 0;
  int unsigned test_drain_time_us = 1000;
  string name;

  function new(virtual rt_interface intf,string name = "rt_base_t");
    env = new(intf);
    this.name = name; // set name
  endfunction

  virtual task run();
    $display("[Test] running %s", name);
    env.run();
  endtask

  task report();
    wait(gen_trans_done == 1'b1); // wait for gen_trans_done); // wait for gen_trans_done
    #(test_drain_time_us * 1us);
    env.report(this.name);
  endtask

  task automatic set_trans_done(bit done = 1);
    gen_trans_done = done;
    #(test_drain_time_us * 1us);
    env.report(this.name);
    $display("[Test] generated = %0d, compared = %0d",
             env.gen.generated_count, env.chk.compare_count);
    if (env.chk.error_count != 0 ||
        env.chk.compare_count == 0 ||
        env.chk.compare_count != env.gen.generated_count ||
        !env.chk.check_data_buffer())
      $fatal(1, "[Test] %s failed after drain timeout; inspect busy_n/frameo_n/valido_n", name);
    $finish(); // terminate the current test
  endtask
endclass


class rt_single_ch_test extends rt_base_test;
  rand bit signed [4:0] src = -1;
  rand bit signed [4:0] dst = -1;
  rand int unsigned pkt_count = 10;
  constraint test_cstr{
    soft pkt_count inside {[1:15]};
    src inside {[-1:15]};
    dst inside {[-1:15]};
  }

  function new(virtual rt_interface intf,string name = "rt_single_ch_test");
    super.new(intf,name);
  endfunction

  task run();
    rt_packet p;    
    super.run(); // run stage
    for (int cnt = 0;cnt < this.pkt_count;cnt++) begin
       p = new();
      //  p.randomize() with {(local::src >=0) ->src == local::src;
      //                      (local::dst >=0) ->dst == local::dst;};
      //  p.randomize() with {src == 3; dst ==6;};
       if (!p.randomize() with {
         (local::src >= 0) -> src == local::src;
         (local::dst >= 0) -> dst == local::dst;
       })
         $fatal(1, "[Test] %s packet randomization failed at packet %0d", name, cnt);
      //  p.data = '{8'h66,8'h77};
       env.gen.put_pkt(p);
    end

    // p = new();
    // // p.set_members(0,1,'{8'h33,8'h77,8'h88});
    // p.randomize() with {src == 0; dst == 3; data.size() == 2; data[0]==8'h33; data[1]==8'h77;};
    // env.gen.put_pkt(p);
    // p = new();
    // // p.set_members(0,2,'{8'h44,8'h55});
    // p.randomize() with {src == 0; dst == 2; data.size() == 2; data[0]==8'h44; data[1]==8'h55;};
    // env.gen.put_pkt(p);
    set_trans_done(); // gen_trans_done
  endtask
endclass

class rt_two_ch_test extends rt_base_test;
  rand bit [3:0] src[2];
  rand bit [3:0] dst[2];
  rand int unsigned pkt_count = 10;
  constraint two_ch_cstr{
    soft pkt_count inside {[20:30]};
    foreach(src[i]) src[i] inside {[0:15]};
    foreach(dst[i]) dst[i] inside {[0:15]};
    unique {src};
  }
  constraint unique_dst_cstr {
    unique {dst};
  }
  
  function new(virtual rt_interface intf,string name = "rt_two_ch_test");
    super.new(intf,name);
  endfunction

  task run();
    rt_packet p;
    super.run();
    if (!this.randomize())
      $fatal(1, "[Test] %s test randomization failed", name);
    for(int cnt = 0;cnt < this.pkt_count;cnt++) begin
      foreach(src[i]) begin
        p = new();
        if (!p.randomize() with {src == local::src[i]; dst == local::dst[i];})
          $fatal(1, "[Test] %s packet randomization failed at packet %0d channel %0d",
                 name, cnt, i);
        env.gen.put_pkt(p);
      end
    end
    set_trans_done(); // gen_trans_done
  endtask

endclass

class rt_two_ch_same_chnout_test extends rt_two_ch_test;
  rand bit [3:0] same_dst;
  constraint two_ch_same_chout_cstr{
    foreach(dst[i]) dst[i] == same_dst; // same dst for two chs
    same_dst inside {[0:15]}; // same dst for two chs
    unique {src}; // unique src for two chs
    // soft pkt_count inside {[10:15]};
    // unique {src}; // unique src for two chs
  }
  function new(virtual rt_interface intf,string name = "rt_two_ch_same_chnout_test");
    super.new(intf,name);
    // Disable only the inherited destination-uniqueness rule.
    unique_dst_cstr.constraint_mode(0);
  endfunction
endclass

class rt_multi_ch_test extends rt_base_test;
  rand bit [4:0] ch_num;
  rand bit [3:0] src[];
  rand bit [3:0] dst[];
  rand int unsigned pkt_count = 10;
  constraint multi_ch_cstr{
    ch_num inside {[1:16]};
    soft pkt_count inside {[10:15]};
    src.size() == ch_num;
    dst.size() == ch_num;
    foreach(src[i]) src[i] inside {[0:15]};
    foreach(dst[i]) dst[i] inside {[0:15]};
    unique {src};
    unique {dst};
  }
  function new(virtual rt_interface intf,string name = "rt_multi_ch_test");
    super.new(intf,name);
    
  endfunction

  task run();
    rt_packet p;
    super.run();
    if (!this.randomize())
      $fatal(1, "[Test] %s test randomization failed", name);
    for(int cnt = 0;cnt < this.pkt_count;cnt++) begin
      foreach(src[i]) begin
        p = new();
        if (!p.randomize() with {src == local::src[i]; dst == local::dst[i];})
          $fatal(1, "[Test] %s packet randomization failed at packet %0d channel %0d",
                 name, cnt, i);
        env.gen.put_pkt(p);
      end
    end
    set_trans_done(); // gen_trans_done
  endtask
endclass

class rt_full_ch_test extends rt_multi_ch_test;
  constraint full_ch_cstr { ch_num == 16; }
  function new(virtual rt_interface intf,string name = "rt_full_ch_test");
    super.new(intf,name);
  endfunction
endclass

endpackage

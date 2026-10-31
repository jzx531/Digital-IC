`timescale 1ns/1ps

interface mcdt_chnl_intf(input logic clk, input logic rstn);
  logic [31:0] ch_data;
  logic        ch_valid;
  logic        ch_ready;
  logic [5:0]  ch_margin;
endinterface

interface mcdt_out_intf(input logic clk, input logic rstn);
  logic [31:0] mcdt_data;
  logic        mcdt_val;
  logic [1:0]  mcdt_id;
endinterface

package mcdt_tb_pkg;

  typedef struct packed {
    bit [31:0] data;
    bit [1:0]  id;
  } mcdt_mon_data_t;

  class mcdt_chnl_trans;
    rand bit [31:0] data[];
    rand int ch_id;
    rand int pkt_id;
    rand int data_nidles;
    rand int pkt_nidles;
    bit rsp;

    constraint cstr {
      soft data.size() inside {[4:8]};
      foreach (data[i])
        data[i] == 32'hc000_0000 + (ch_id << 24) + (pkt_id << 8) + i;
      soft ch_id == 0;
      soft pkt_id == 0;
      data_nidles inside {[0:2]};
      pkt_nidles inside {[1:10]};
    }

    function mcdt_chnl_trans clone();
      mcdt_chnl_trans c = new();
      c.data = data;
      c.ch_id = ch_id;
      c.pkt_id = pkt_id;
      c.data_nidles = data_nidles;
      c.pkt_nidles = pkt_nidles;
      c.rsp = rsp;
      return c;
    endfunction
  endclass

  class mcdt_chnl_initiator;
    local string name;
    local virtual mcdt_chnl_intf intf;
    mailbox #(mcdt_chnl_trans) req_mb;
    mailbox #(mcdt_chnl_trans) rsp_mb;

    function new(string name = "mcdt_chnl_initiator");
      this.name = name;
    endfunction

    function void set_interface(virtual mcdt_chnl_intf intf);
      if (intf == null)
        $fatal(1, "[%s] interface handle is null", name);
      this.intf = intf;
    endfunction

    task run();
      mcdt_chnl_trans req;
      mcdt_chnl_trans rsp;
      @(posedge intf.rstn);
      forever begin
        req_mb.get(req);
        mcdt_chnl_write(req);
        rsp = req.clone();
        rsp.rsp = 1'b1;
        rsp_mb.put(rsp);
      end
    endtask

    task mcdt_chnl_write(input mcdt_chnl_trans t);
      foreach (t.data[i]) begin
        @(posedge intf.clk);
        intf.ch_valid <= 1'b1;
        intf.ch_data <= t.data[i];
        do @(negedge intf.clk); while (intf.ch_ready !== 1'b1);
        repeat (t.data_nidles) mcdt_chnl_idle();
      end
      repeat (t.pkt_nidles) mcdt_chnl_idle();
    endtask

    task mcdt_chnl_idle();
      @(posedge intf.clk);
      intf.ch_valid <= 1'b0;
      intf.ch_data <= 32'b0;
    endtask
  endclass

  class mcdt_chnl_generator;
    rand int pkt_id = -1;
    rand int ch_id = -1;
    rand int data_nidles = -1;
    rand int pkt_nidles = -1;
    rand int data_size = -1;
    rand int ntrans = 10;
    mailbox #(mcdt_chnl_trans) req_mb;
    mailbox #(mcdt_chnl_trans) rsp_mb;
    int generated_words;

    constraint cstr {
      soft ch_id == -1;
      soft pkt_id == -1;
      soft data_size == -1;
      soft data_nidles == -1;
      soft pkt_nidles == -1;
      soft ntrans == 10;
    }

    function new();
      req_mb = new();
      rsp_mb = new();
      generated_words = 0;
    endfunction

    task run();
      repeat (ntrans) mcdt_send_trans();
    endtask

    task mcdt_send_trans();
      mcdt_chnl_trans req = new();
      mcdt_chnl_trans rsp;
      assert (req.randomize() with {
        local::ch_id >= 0 -> ch_id == local::ch_id;
        local::pkt_id >= 0 -> pkt_id == local::pkt_id;
        local::data_nidles >= 0 -> data_nidles == local::data_nidles;
        local::pkt_nidles >= 0 -> pkt_nidles == local::pkt_nidles;
        local::data_size > 0 -> data.size() == local::data_size;
      }) else $fatal(1, "[RNDFAIL] channel transaction randomization failed");
      generated_words += req.data.size();
      pkt_id = (pkt_id < 0) ? 1 : pkt_id + 1;
      req_mb.put(req);
      rsp_mb.get(rsp);
      assert (rsp.rsp)
        else $fatal(1, "[RSPERR] %0t channel response failed", $time);
    endtask
  endclass

  class mcdt_chnl_monitor;
    local string name;
    local int channel_id;
    local virtual mcdt_chnl_intf intf;
    mailbox #(mcdt_mon_data_t) mon_mb;

    function new(string name = "mcdt_chnl_monitor", int channel_id = 0);
      this.name = name;
      this.channel_id = channel_id;
    endfunction

    function void set_interface(virtual mcdt_chnl_intf intf);
      if (intf == null)
        $fatal(1, "[%s] interface handle is null", name);
      this.intf = intf;
    endfunction

    task run();
      mcdt_mon_data_t m;
      forever begin
        @(posedge intf.clk iff
          (intf.rstn === 1'b1 && intf.ch_valid === 1'b1 && intf.ch_ready === 1'b1));
        m.data = intf.ch_data;
        m.id = channel_id[1:0];
        mon_mb.put(m);
      end
    endtask
  endclass

  class mcdt_output_monitor;
    local string name;
    local virtual mcdt_out_intf intf;
    mailbox #(mcdt_mon_data_t) mon_mb;

    function new(string name = "mcdt_output_monitor");
      this.name = name;
    endfunction

    function void set_interface(virtual mcdt_out_intf intf);
      if (intf == null)
        $fatal(1, "[%s] interface handle is null", name);
      this.intf = intf;
    endfunction

    task run();
      mcdt_mon_data_t m;
      forever begin
        @(posedge intf.clk iff (intf.rstn === 1'b1 && intf.mcdt_val === 1'b1));
        m.data = intf.mcdt_data;
        m.id = intf.mcdt_id;
        mon_mb.put(m);
      end
    endtask
  endclass

  class mcdt_checker;
    mailbox #(mcdt_mon_data_t) in_mbs[3];
    mailbox #(mcdt_mon_data_t) out_mb;
    int error_count;
    int cmp_count;

    function new();
      foreach (in_mbs[i]) in_mbs[i] = new();
      out_mb = new();
      error_count = 0;
      cmp_count = 0;
    endfunction

    task run();
      mcdt_mon_data_t im;
      mcdt_mon_data_t om;
      forever begin
        out_mb.get(om);
        case (om.id)
          2'd0: in_mbs[0].get(im);
          2'd1: in_mbs[1].get(im);
          2'd2: in_mbs[2].get(im);
          default: $fatal(1, "[IDERR] invalid MCDT output id %0d", om.id);
        endcase
        cmp_count++;
        if (om.data !== im.data) begin
          error_count++;
          $error("[CMPFAIL] #%0d output id=%0d data=%08x, expected=%08x",
                 cmp_count, om.id, om.data, im.data);
        end
      end
    endtask
  endclass

  class mcdt_chnl_agent;
    mcdt_chnl_initiator init;
    mcdt_chnl_monitor mon;

    function new(string name = "mcdt_chnl_agent", int channel_id = 0);
      init = new({name, ".init"});
      mon = new({name, ".mon"}, channel_id);
    endfunction

    function void set_interface(virtual mcdt_chnl_intf vif);
      init.set_interface(vif);
      mon.set_interface(vif);
    endfunction

    task run();
      fork
        init.run();
        mon.run();
      join
    endtask
  endclass

  class mcdt_root_test;
    mcdt_chnl_generator gen[3];
    mcdt_chnl_agent agents[3];
    mcdt_output_monitor mcdt_mon;
    mcdt_checker chker;
    protected string name;
    virtual mcdt_out_intf mcdt_vif;

    function new(string name = "mcdt_root_test");
      this.name = name;
      chker = new();
      foreach (agents[i]) begin
        agents[i] = new($sformatf("mcdt_agents[%0d]", i), i);
        gen[i] = new();
        agents[i].init.req_mb = gen[i].req_mb;
        agents[i].init.rsp_mb = gen[i].rsp_mb;
        agents[i].mon.mon_mb = chker.in_mbs[i];
      end
      mcdt_mon = new();
      mcdt_mon.mon_mb = chker.out_mb;
    endfunction

    virtual function void set_interface(
        virtual mcdt_chnl_intf ch0_vif,
        virtual mcdt_chnl_intf ch1_vif,
        virtual mcdt_chnl_intf ch2_vif,
        virtual mcdt_out_intf out_vif
    );
      agents[0].set_interface(ch0_vif);
      agents[1].set_interface(ch1_vif);
      agents[2].set_interface(ch2_vif);
      mcdt_mon.set_interface(out_vif);
      mcdt_vif = out_vif;
    endfunction

    virtual function void do_config();
    endfunction

    virtual task run();
      int expected_words;
      int wait_cycles;
      do_config();
      fork
        agents[0].run();
        agents[1].run();
        agents[2].run();
        mcdt_mon.run();
        chker.run();
      join_none
      fork
        gen[0].run();
        gen[1].run();
        gen[2].run();
      join

      expected_words = gen[0].generated_words +
                       gen[1].generated_words +
                       gen[2].generated_words;
      wait_cycles = 0;
      while ((chker.cmp_count < expected_words) && (wait_cycles < 100000)) begin
        @(posedge mcdt_vif.clk);
        wait_cycles++;
      end
      if (chker.cmp_count != expected_words)
        $fatal(1, "[TIMEOUT] compared %0d of %0d expected words",
               chker.cmp_count, expected_words);
      repeat (5) @(posedge mcdt_vif.clk);
      if (chker.error_count == 0) begin
        $display("============================================================");
        $display("[TEST PASS] %s compared %0d words with no errors",
                 name, chker.cmp_count);
        $display("============================================================");
        $finish;
      end
      else
        $fatal(1, "[TEST FAIL] %s found %0d compare errors in %0d words",
               name, chker.error_count, chker.cmp_count);
    endtask
  endclass

  class mcdt_basic_test extends mcdt_root_test;
    function new(string name = "mcdt_basic_test");
      super.new(name);
    endfunction

    virtual function void do_config();
      int n0;
      int n1;
      int n2;
      super.do_config();
      if ($test$plusargs("SMOKE")) begin
        n0 = 8;
        n1 = 6;
        n2 = 4;
      end
      else begin
        n0 = 100;
        n1 = 50;
        n2 = 80;
      end
      assert (gen[0].randomize() with {
        ntrans == n0; ch_id == 0; data_nidles == 0;
        pkt_nidles == 1; data_size == 8;
      }) else $fatal(1, "[RNDFAIL] gen[0] randomization failed");
      assert (gen[1].randomize() with {
        ntrans == n1; ch_id == 1; data_nidles inside {[1:2]};
        pkt_nidles inside {[3:5]}; data_size == 6;
      }) else $fatal(1, "[RNDFAIL] gen[1] randomization failed");
      assert (gen[2].randomize() with {
        ntrans == n2; ch_id == 2; data_nidles inside {[0:1]};
        pkt_nidles inside {[1:2]}; data_size == 32;
      }) else $fatal(1, "[RNDFAIL] gen[2] randomization failed");
    endfunction
  endclass

endpackage

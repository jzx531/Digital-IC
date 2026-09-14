`timescale 1ns/1ps
module tb;
  event e1,e2,e3;
  task wait_event(event e,string name);
    $display("Waiting for %s",name);
    @(e);
    $display("Received %s",name);
  endtask

  initial begin
    fork 
        wait_event(e1,"e1");
        wait_event(e2,"e2");
        wait_event(e3,"e3");
    join
  end

  initial begin
    fork 
        begin #10ns -> e1; end
        begin #20ns -> e2; end
        begin #30ns -> e3; end
    join
  end

endmodule

// event 先触发 再wait会被阻塞
// 而使用wait_event(ref logic e,string name) 可以解决这个问题
module tb2;
  bit e1,e2,e3;

  task automatic wait_event(ref logic e,string name);
    $display("@%t start waiting event %s",$time,name);
    @e;
    $display("@%t received event %s",$time,name);
  endtask

  initial begin
    fork
       wait_event(e1,"e1");
       wait_event(e2,"e2");
       wait_event(e3,"e3");
    join
  end

  initial begin
        fork
            begin #10ns e1 = !e1; end
            begin #20ns e2 = !e2; end
            begin #30ns e3 = !e3; end
        join
    end
endmodule


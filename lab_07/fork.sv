`timescale 1ns/1ps

module tb;
    taak automatic exec(int id, int t);
    $display("Task %d started at %t", id, $time);
    #(t) * 1ns;
    $display("Task %d finished at %t", id, $time);


initial begin
    exec(1,10);
end

initial begin
    exec(2,20);
end

initial begin
    exec(3,30);
end


endmodule



module tb2
    task automatic exec(int id, int t);
    $display("Task %d started at %t", id, $time);
    #(t) * 1ns;
    $display("Task %d finished at %t", id, $time);
    endtask

    initial begin
      fork 
        exec(1,10);
        exec(2,20);
        exec(3,30);
      join_any

      $display("All tasks finished join any at %t", $time);

      fork 
        exec(1,10);
        exec(2,20);
        exec(3,30);
      join

      $display("All tasks finished join all at %t", $time);

      fork
        exec(1,10);
        exec(2,20);
        exec(3,30);
      join_none
        $display("All tasks finished join_none at %t", $time);
    end
endmodule






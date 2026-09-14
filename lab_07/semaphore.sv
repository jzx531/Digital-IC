module tb;
    semaphore mem_acc_key;

    int unsigned mem[int unsigned];

    task automatic write(int unsigned addr, int unsigned data);
        mem_acc_key.get();
        mem[addr] = data;
        mem_acc_key.put();
    endtask
    
    task automatic read(int unsigned addr, output int unsigned data);
        mem_acc_key.get();
        if(mem.exists(addr))
            data =mem[addr];
        else
            data 'x;

        mem_acc_key.put();
    endtask

    initial begin
        mem_acc_key = new(1);
        int unsigned data;
        
        forever begin
            fork
                // case($urandom() %2)
                //     0: begin write($urandom(0,3) << 2, $urandom(0,16)); end
                //     1: begin read($urandom(0,3) << 2, data); $display("read %0d from %0d", data, $urandom(0,3) << 2); end
                // endcase

              begin
                #10ns;
                write('h10,data + 100);
                $display("write %0d to %0d", data + 100, 'h10);
              end

              begin
                #10ns;
                read('h10,data);
                $display("read %0d from %0d", data, 'h10);
              end
            join
        end
    end

endmodule


module tb;
    mailbox #(int) mb;
    /**
    * 信箱写满时,继续写入，会等待而不是丢失 除非try_put返回0
    * 信箱为空时,读取会阻塞，try_put返回0
    */

    initial begin
        int data;
        mb = new(8);
        forever begin
           case ($urandom(0,1))
              0: begin 
                // if(mb.num()<8) begin
                //     data = $urandom(0,10);
                //     mb.put(data); 
                //     $display("Sent data: %d", data); 
                // end
                data = $urandom(0,10);
                if(mp.try_put(data) == 1)
                   begin
                        $display("Sent data: %d", data); 
                   end
                   else
                    begin
                        $display("Failed to send data"); 
                    end
                    
                end
              1: begin 
                    if(mb.num()>0) begin
                        mb.get(data); 
                        $display("Received data: %d", data); 
                    end
                end
           endcase
        end

    end

endmodule

 
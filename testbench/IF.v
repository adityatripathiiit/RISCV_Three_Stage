module IF(
          input clk,
          output [31:0] pc_current,
          output [31:0] Instruction
         );

reg [31:0] Instruction;
reg [31:0] pc_current,pc_temp,PC;
integer itr = 0,temp,temp1;

initial
begin
PC = 32'd0;
end
                   
                     always @(negedge clk)
                     begin
                     
                     if(itr == 0)
                     begin
                         pc_temp = PC;
                         pc_current = PC;
                     end
                     
                     for (itr=0;itr<4;itr=itr+1)
                     begin
                         temp = 8*itr;
                         temp1 = temp+7;
                         Instruction[8*itr+:8] = Pipe.MEM1.Memory[pc_temp];
                         pc_temp = pc_temp + 1;
                     end
                        
                     pc_current = pc_temp - 4;
                     
                     $display("%b", Instruction);
                     
                     end


                     
endmodule


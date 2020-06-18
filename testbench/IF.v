module IF(
          input clk,
          output [31:0] pc_current,
          output [31:0] Instruction
         );

reg [31:0] Instruction;
reg [31:0] pc_current,pc_temp,PC;
integer itr = 0;

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
                         Instruction[8*itr+7:8*itr] = Pipe.MEM1.Memory[pc_temp];
                         pc_temp = pc_temp + 1;
                     end
                        
                     pc_current = pc_temp - 4;
                     
                     
                     end
                     
endmodule


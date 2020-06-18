`include "IF.v"
`include "mem.v"
module Pipeline (input clk);
 
wire clk;
wire [31:0] pc_current,Instruction,Dm1,Dm2;
reg [31:0]Am1,Am2,Dm3,D3;
integer ind1,i2,i3;
reg RW;

// ---------CREATING--INSTANCES--------------

     
     IF                IF1(.clk(clk),.pc_current(pc_current),.Instruction(Instruction));
     
     mem               MEM1();                
                 
                     
                    
                     
 endmodule                     
                   
                   
                   

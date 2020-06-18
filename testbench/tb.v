`include "Pipeline.v"

module tb();


reg clk;
reg [31:0] Buffer[32'h1000:0];

integer itr,i4,i2;
integer Hex_mem,temp,count=0,temp1,temp2;

Pipeline  Pipe (.clk(clk));

initial 
       begin
       clk = 0;
       i2 = 1;
       i4 = 0;
       
                     Hex_mem = $fopen("Input_Memory","r");  //add location of hex file
                     temp = $fgetc(Hex_mem);
                     while (!$feof(Hex_mem))
                      begin
                         if (temp == "\n")
                            count = count+1;
                            temp = $fgetc(Hex_mem); 

                      end       
                         $readmemh("Input_Memory",Buffer,0,2*count-1);  //add location of hex file
                         for(itr = 0;itr < 32'h1000;itr = itr + 1)
                         begin
                             if (i4 == 4)
                             begin      
                               i4 = 0;
                               i2 = i2 + 2;
                             end
                          temp1 = 8*i4;
                          temp2 = temp1 +7;
                         Pipe.MEM1.Memory[itr] = Buffer [i2] [8*itr+:8];
                         i4 = i4 + 1;
                         
                       end
                      
       
       $finish;
       
       end
       
       
       always 
       begin
          # 5 clk = ~clk;
       end
       
       endmodule
       

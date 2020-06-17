`include "rv32_opcodes.vh"	//Change file name

`timescale 1ns/1ps

module register_file(
	input						clk,
	input[`REG_ADDR_WIDTH-1:0]	rs1,	//change parameter name
	output[`XPR_LEN-1:0]		rd1,
	input[`REG_ADDR_WIDTH-1:0]	rs2,
	output[`XPR_LEN-1:0]		rd2,
	input						write_en,
	input[`REG_ADDR_WIDTH-1:0]	write_addr,
	input[`XPR_LEN-1:0]			write_data
);

reg[`XPR_LEN-1:0]	memory[31:0];
wire 				temp;

//temp assigned to zero if write disabled or write address zero
assign temp = write_en && |write_addr;	//|write_addr does bitwise or of write_addr[0:4]

assign rd1 = |rs1? memory[rs1]:0;	//if rs1 is not zero then rd1 is assigned its value in memory

assign rd2 = |rs2? memory[rs2]:0;

always @(posedge clk)
	begin
		if(temp)
			begin
				memory[write_addr] <= write_data;
			end
	end

/*
`ifndef SYNTHESIS	//if SYNTHESIS is not defined using `define above then the code gets executed to populated memory randomly
integer i;
initial
	begin
		for(i=0;i<32;i=i+1)
			begin
				memory[i] = $random;
			end
	end
`endif
*/

endmodule
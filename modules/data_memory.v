`timescale 1ns/1ps

module data_memory(
	input			clk,
	input			dmem_wen,
	input[31:0]		dmem_wdata,
	input[13:0]		dmem_waddr,	//check address size
	input			dmem_ren,
	input[13:0]		dmem_raddr,	//check address size
	output[31:0]	dmem_rdata
);

parameter mem_depth = 16384;

reg[31:0]	memory[0:mem_depth-1];
reg[31:0]	temp;

integer i;

always @(posedge clk)
	begin
		if	(dmem_wen)
			begin
				memory[dmem_waddr] <= dmem_wdata;
			end
	end

always @(posedge clk)
	begin
		if	(dmem_ren)
			begin
				temp <= memory[dmem_raddr];
			end
	end

assign dmem_rdata = temp;

endmodule

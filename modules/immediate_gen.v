`include "vscale_ctrl_constants.vh"	//change header names
`include "rv32_opcodes.vh"			//change header names

`timescale 1ns/1ps

module imm_gen(
	input[`XPR_LEN-1:0]			inst,	//XPR_LEN is length of instruction = 32
	input[`IMM_TYPE_WIDTH-1:0]	type,	//type width is 2 defining I,U,J and S type
	output reg[`XPR_LEN-1:0]	imm
);

reg[20:0] temp_1 = 21{inst[31]};
reg[11:0] temp_2 = 12{inst[31]};	//For J type instruction

always @(*)
	begin
		case(type)
			`IMM_I: imm = {temp_1,inst[30:20]};
			`IMM_S: imm = {temp_1,inst[30:25],inst[11:7]};
			`IMM_U: imm = {inst[31:12],12'b0};
			`IMM_J: imm = {temp_2,inst[19:12],inst[20],inst[30:25],inst[24:21],1'b0};

			default: imm = {temp_1,inst[30:20]};
		endcase
	end

endmodule
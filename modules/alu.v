`include "ALUOpcodes.vh"
`include "RV32Opcodes.vh"

`timescale 1ns/1ps
// Changed names of in1 and in2 to input1 and input2 
// changed names of the modules from vscale_alu to alu
// changed op to opcode

module alu(
    input [`ALU_OPCODE_WIDTH-1:0] opcode,
    input [`XPR_LEN-1:0] input1,
    input [`XPR_LEN-1:0] input2,
    output reg [`XPR_LEN-1:0] out
);

wire [`SHAMT_WIDTH-1:0] shamt;

assign shamt = input2[`SHAMT_WIDTH-1:0];

always @(*) begin
    // case statement  on opcode
    case (opcode)
        `ALU_OPCODE_ADD : out = input1 + input2;
        `ALU_OPCODE_SLL : out = input1 << shamt;
        `ALU_OPCODE_XOR : out = input1 ^ input2;
        `ALU_OPCODE_OR : out = input1 | input2;
        `ALU_OPCODE_AND : out = input1 & input2;
        `ALU_OPCODE_SRL : out = input1 >> shamt;
        `ALU_OPCODE_SEQ : out = {31'b0, input1 == input2};
        `ALU_OPCODE_SNE : out = {31'b0, input1 != input2};
        `ALU_OPCODE_SUB : out = input1 - input2;
        `ALU_OPCODE_SRA : out = $signed(input1) >>> shamt;
        `ALU_OPCODE_SLT : out = {31'b0, $signed(input1) < $signed(input2)};
        `ALU_OPCODE_SGE : out = {31'b0, $signed(input1) >= $signed(input2)};
        `ALU_OPCODE_SLTU : out = {31'b0, input1 < input2};
        `ALU_OPCODE_SGEU : out = {31'b0, input1 >= input2};
        default : out = 0;
    endcase 
end

endmodule 

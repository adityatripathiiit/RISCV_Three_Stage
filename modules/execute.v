////////////////////////////////////////////////////////////
// Stage 2: Execute
////////////////////////////////////////////////////////////

module execute 
 #(
                    parameter  [31:0]    RESET   = 32'h0000_0000
//                  parameter  [ 2: 0]   ADD     = 3'b000,    // inst[30] == 0: ADD, inst[31] == 1: SUB
//                  parameter  [ 2: 0]   SLL     = 3'b001,
//                  parameter  [ 2: 0]   SLT     = 3'b010,
//                  parameter  [ 2: 0]   SLTU    = 3'b011,
//                  parameter  [ 2: 0]   XOR     = 3'b100,
//                  parameter  [ 2: 0]   SR      = 3'b101,    // inst[30] == 0: SRL, inst[31] == 1: SRA
//                  parameter  [ 2: 0]   OR      = 3'b110,
//                  parameter  [ 2: 0]   AND     = 3'b111,

//                     // FUNC3, INST[14:12], INST[6:0] = 7'b0100011
//                   parameter  [ 2: 0]  SB      = 3'b000,
//                   parameter  [ 2: 0]  SH      = 3'b001,
//                   parameter  [ 2: 0]  SW      = 3'b010,
//                   parameter  [31: 0]  RESETVEC   = 32'h0000_0000

                    ) 

                (input clk,
                input reset,
                input           immediate_sel,
                input[31:0]     immediate,
                input           mem_write,
                input           mem_to_reg,
                input           jal,
                input           jalr,
                input           lui,
                input           alu,
                input [2:0]     alu_operation,
                input           arithsubtype,
                input[31:0]     pc,
                input [4:0]     dest_reg_sel            
             );

    `include "opcode.vh"
    
    reg             [31:0]  fetch_pc;           
    wire            [31:0]  reg_rdata1 ;         
    wire            [31:0]  reg_rdata2 ;         
    

    wire            [32: 0] result_subs;        //Substraction Signed
    wire            [32: 0] result_subu;        //Substraction Unsigned
    reg             [31: 0] result;
    reg             [31: 0] next_pc;
    wire            [31: 0] write_address;


// Selecting the first and second operands of ALU unit
wire[31:0] alu_operand1;
wire[31:0] alu_operand2;
assign alu_operand1       = reg_rdata1;
assign alu_operand2       = (immediate_sel) ? immediate : reg_rdata2;

assign result_subs[32: 0]   = {alu_operand1[31], alu_operand1} - {alu_operand2[31], alu_operand2};
assign result_subu[32: 0]   = {1'b0, alu_operand1} - {1'b0, alu_operand2};
assign write_address              = alu_operand1 + immediate;

//Calculating next pc value

always @(*) 
begin
    next_pc      = fetch_pc + 4;
end

//Calculating result depending on the opcode

always @(*) 
begin
    case(1'b1)
        mem_write:   result          = alu_operand2;
        jal:     result          = pc + 4;
        jalr:    result          = pc + 4;
        lui:     result          = immediate;

        alu:
            case(alu_operation)
                ADD : if (arithsubtype == 1'b0)
                            result  = alu_operand1 + alu_operand2;
                         else
                            result  = alu_operand1 - alu_operand2;
                SLL : result     = alu_operand1 << alu_operand2;
                SLT : result     = result_subs[32] ? 'd1 : 'd0;
                SLTU: result     = result_subu[32] ? 'd1 : 'd0;
                XOR : result     = alu_operand1 ^ alu_operand2;
                SR  : if (arithsubtype == 1'b0)
                            result  = alu_operand1 >>> alu_operand2;
                         else
                            result  = $signed(alu_operand1) >>> alu_operand2;
                OR  : result     = alu_operand1 | alu_operand2;
                AND : result     = alu_operand1 & alu_operand2;
                default: result     = 'hx;
            endcase
        default: result = 'hx;
    endcase
end

//Preparing output for writeback stage

always @(posedge clk or negedge reset) 
begin
    if (!reset) 
    begin
        fetch_pc <= RESET;
    end 
end


endmodule
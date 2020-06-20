////////////////////////////////////////////////////////////
//      F/D  E   W
//          F/D  E   W
//              F/D  E  W
//                  F/D E  w 
////////////////////////////////////////////////////////////
// Stage 2: Execute
////////////////////////////////////////////////////////////

// `include "opcode.vh"

module execute #(parameter  [ 2: 0]   OP_ADD     = 3'b000,    // inst[30] == 0: ADD, inst[31] == 1: SUB
                 parameter  [ 2: 0]   OP_SLL     = 3'b001,
                 parameter  [ 2: 0]   OP_SLT     = 3'b010,
                 parameter  [ 2: 0]   OP_SLTU    = 3'b011,
                 parameter  [ 2: 0]   OP_XOR     = 3'b100,
                 parameter  [ 2: 0]   OP_SR      = 3'b101,    // inst[30] == 0: SRL, inst[31] == 1: SRA
                 parameter  [ 2: 0]   OP_OR      = 3'b110,
                 parameter  [ 2: 0]   OP_AND     = 3'b111,

                    // FUNC3, INST[14:12], INST[6:0] = 7'b0100011
                  parameter  [ 2: 0]  OP_SB      = 3'b000,
                  parameter  [ 2: 0]  OP_SH      = 3'b001,
                  parameter  [ 2: 0]  OP_SW      = 3'b010,
                  parameter  [31: 0]  RESETVEC   = 32'h0000_0000

                    ) 

                (input clk,
                input resetb,
                input           ex_imm_sel,
                input[31:0]     ex_imm,
                input           ex_memwr,
                input           ex_mem2reg,
                input           ex_jal,
                input           ex_jalr,
                input           ex_lui,
                input           ex_auipc,
                input           ex_csr,
                input           ex_alu,
                input [2:0]      ex_alu_op,
                input           ex_subtype,
                input[31:0]     ex_pc,
                input [4:0]     ex_dst_sel            
             );
    
    reg             [31:0]  ex_csr_read;        //should be assigned a value for testing ..changes in writeback stage
    reg             [31:0]  fetch_pc;           //should be assigned a value for testing ..changes in writeback stage
    wire            [31:0]  reg_rdata1 ;         //should be assigned a value for testing ..changes in writeback stage
    wire            [31:0]  reg_rdata2 ;         //should be assigned a value for testing ..changes in writeback stage
    

    wire            [32: 0] result_subs;        //Substraction Signed
    wire            [32: 0] result_subu;        //Substraction Unsigned
    reg             [31: 0] result;
    reg             [31: 0] next_pc;
    wire            [31: 0] wr_addr;


// Selecting the first and second operands of ALU unit
wire[31:0] alu_op1;
wire[31:0] alu_op2;
assign alu_op1       = reg_rdata1;
assign alu_op2       = (ex_imm_sel) ? ex_imm : reg_rdata2;

assign result_subs[32: 0]   = {alu_op1[31], alu_op1} - {alu_op2[31], alu_op2};
assign result_subu[32: 0]   = {1'b0, alu_op1} - {1'b0, alu_op2};
assign wr_addr              = alu_op1 + ex_imm;

//Calculating next pc value

always @(*) 
begin
    next_pc      = fetch_pc + 4;
end

//Calculating result depending on the opcode

always @(*) 
begin
    case(1'b1)
        ex_memwr:   result          = alu_op2;
        ex_jal:     result          = ex_pc + 4;
        ex_jalr:    result          = ex_pc + 4;
        ex_lui:     result          = ex_imm;
        ex_auipc:   result          = ex_pc + ex_imm;

        ex_csr:     result          = ex_csr_read;

        ex_alu:
            case(ex_alu_op)
                OP_ADD : if (ex_subtype == 1'b0)
                            result  = alu_op1 + alu_op2;
                         else
                            result  = alu_op1 - alu_op2;
                OP_SLL : result     = alu_op1 << alu_op2;
                OP_SLT : result     = result_subs[32] ? 'd1 : 'd0;
                OP_SLTU: result     = result_subu[32] ? 'd1 : 'd0;
                OP_XOR : result     = alu_op1 ^ alu_op2;
                OP_SR  : if (ex_subtype == 1'b0)
                            result  = alu_op1 >>> alu_op2;
                         else
                            result  = $signed(alu_op1) >>> alu_op2;
                OP_OR  : result     = alu_op1 | alu_op2;
                OP_AND : result     = alu_op1 & alu_op2;
                default: result     = 'hx;
            endcase
        default: result = 'hx;
    endcase
end

//Preparing output for writeback stage

always @(posedge clk or negedge resetb) 
begin
    if (!resetb) 
    begin
        fetch_pc <= RESETVEC;
    end 
end


endmodule
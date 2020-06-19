////////////////////////////////////////////////////////////
//      F/D  E   W
//          F/D  E   W
//              F/D  E  W
//                  F/D E  w 
////////////////////////////////////////////////////////////
// stage 1: fetch/decode
////////////////////////////////////////////////////////////

module IF_ID(
    input                   clk,
    input                   resetb,
    output reg              exception,

    // interface of instruction RAM
    output                  imem_ready,
    input           [31: 0] imem_rdata,
    input                   imem_valid,
    output          [31: 0] imem_addr
);

`include "opcode.vh"
// pc wires
reg             [31: 0] if_pc;
reg             [31: 0] ex_pc;

// wires 
reg                     illegal_inst;
reg                     illegal_csr;
reg                     [31: 0] imm;

reg             [31: 0] ex_imm;
reg                     ex_imm_sel;
reg             [ 4: 0] ex_src1_sel;
reg             [ 4: 0] ex_src2_sel;
reg             [ 4: 0] ex_dst_sel;
reg             [ 2: 0] ex_alu_op;
reg                     ex_subtype;
reg                     ex_memwr;
reg                     ex_mem2reg;
reg                     ex_alu;
reg                     ex_csr;
reg                     ex_lui;
reg                     ex_auipc;
reg                     ex_jal;
reg                     ex_jalr;
reg                     ex_branch;
wire reg               [31:0] inst;
initial if_pc = 0;

// reading the instructions and assigning the instruction to inst

////////////////////////////////////////////////////////////////
// IF stage 
////////////////////////////////////////////////////////////////
assign inst                 =  imem_rdata;

// check for illegal instruction(instruction not in RV-32 architechture)
always @(posedge clk or negedge resetb) begin
    if (!resetb)
        exception           <= 1'b0;
    else if (illegal_inst || illegal_csr || imem_addr[1:0] != 0)
        exception           <= 1'b1;
end

////////////////////////////////////////////////////////////////
// IF stage end
////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////
// ID stage 
////////////////////////////////////////////////////////////////

always @* begin
    imm                     = 32'h0;
    illegal_inst            = 1'b0;
    // $monitor("Operation type: %b",inst[`OPCODE]); 
    case(inst[`OPCODE])
        OP_AUIPC : imm      = {inst[31:12], 12'd0}; // U-type
        OP_LUI   : imm      = {inst[31:12], 12'd0}; // U-type
        OP_JAL   : imm      = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}; // J-type
        OP_JALR  : imm      = {{20{inst[31]}}, inst[31:20]}; // I-Type 
        OP_BRANCH: imm      = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0}; // B-type
        OP_LOAD  : imm      = {{20{inst[31]}}, inst[31:20]}; // I-type
        OP_STORE : imm      = {{20{inst[31]}}, inst[31:25], inst[11:7]}; // S-type
        OP_ARITHI: imm      = (inst[`FUNC3] == OP_SLL || inst[`FUNC3] == OP_SR) ? {27'h0, inst[24:20]} : {{20{inst[31]}}, inst[31:20]}; // I-type
        OP_ARITHR: imm      = 'd0; // R-type
        OP_FENCE : imm      = 'd0;
        OP_SYSTEM: imm      = {20'h0, inst[31:20]};
        default: begin // illegal instruction
            illegal_inst    = 1'b1;
            // $display("Illegal instruction");
            // $finish(2);
        end
    endcase
end

always @(posedge clk or negedge resetb) begin

    // If reset of the system is performed, reset all the values. 

    if (!resetb) begin
        ex_imm              <= 32'h0;
        ex_imm_sel          <= 1'b0;
        ex_src1_sel         <= 5'h0;
        ex_src2_sel         <= 5'h0;
        ex_dst_sel          <= 5'h0;
        ex_alu_op           <= 3'h0;
        ex_subtype          <= 1'b0;
        ex_memwr            <= 1'b0;
        ex_mem2reg          <= 1'b0;
        ex_alu              <= 1'b0;
        ex_csr              <= 1'b0;
        ex_jal              <= 1'b0;
        ex_jalr             <= 1'b0;
        ex_branch           <= 1'b0;
        ex_pc               <= RESETVEC;
    end else begin  // else take the values from the IF stage and decode it to pass values to corresponding wires
        ex_imm              <= imm;
        ex_imm_sel          <= (inst[`OPCODE] == OP_JALR  ) ||
                               (inst[`OPCODE] == OP_LOAD  ) ||
                               (inst[`OPCODE] == OP_ARITHI);
        ex_src1_sel         <= inst[`RS1];
        ex_src2_sel         <= inst[`RS2];
        ex_dst_sel          <= inst[`RD];
        ex_alu_op           <= inst[`FUNC3];
        ex_subtype          <= inst[`SUBTYPE] && !(inst[`OPCODE] == OP_ARITHI && inst[`FUNC3] == OP_ADD);
        ex_memwr            <= inst[`OPCODE] == OP_STORE;
        ex_mem2reg          <= inst[`OPCODE] == OP_LOAD;
        ex_alu              <= (inst[`OPCODE] == OP_ARITHI) ||
                               (inst[`OPCODE] == OP_ARITHR);
        ex_csr              <= (inst[`OPCODE] == OP_SYSTEM) && !(inst[`IMM12] == 'h0 || inst[`IMM12] == 'h1);
        ex_lui              <= inst[`OPCODE] == OP_LUI;
        ex_auipc            <= inst[`OPCODE] == OP_AUIPC;
        ex_jal              <= inst[`OPCODE] == OP_JAL;
        ex_jalr             <= inst[`OPCODE] == OP_JALR;
        ex_branch           <= inst[`OPCODE] == OP_BRANCH;
        ex_pc               <= if_pc;
    end
    if_pc <= if_pc+4;
end
initial
      $monitor("Operation type: %s",inst[`OPCODE]);

endmodule


////////////////////////////////////////////////////////////
//      F/D  E   W
//          F/D  E   W
//              F/D  E  W
//                  F/D E  w 
////////////////////////////////////////////////////////////
// Stage 2: Execute
////////////////////////////////////////////////////////////

// `include "opcode.vh"





module execute #(parameter  [ 2: 0] OP_ADD     = 3'b000,    // inst[30] == 0: ADD, inst[31] == 1: SUB
                 parameter  [ 2: 0]   OP_SLL     = 3'b001,
                 parameter  [ 2: 0]   OP_SLT     = 3'b010,
                 parameter  [ 2: 0]   OP_SLTU    = 3'b011,
                 parameter  [ 2: 0]   OP_XOR     = 3'b100,
                 parameter  [ 2: 0]   OP_SR      = 3'b101,    // inst[30] == 0: SRL, inst[31] == 1: SRA
                 parameter  [ 2: 0]   OP_OR      = 3'b110,
                 parameter  [ 2: 0]   OP_AND     = 3'b111,

                    // FUNC3, INST[14:12], INST[6:0] = 7'b0100011
                    parameter  [ 2: 0] OP_SB      = 3'b000,
                  parameter  [ 2: 0]  OP_SH      = 3'b001,
                  parameter  [ 2: 0]  OP_SW      = 3'b010,
                  parameter  [31: 0] RESETVEC   = 32'h0000_0000

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
                input [4:0]     ex_dst_sel,
                input   [31: 0] dmem_rdata,

                // Outputs to Writeback Stage

                output reg [31:0]    wb_result,
                output reg         wb_memwr,
                output reg         wb_alu2reg,
                output reg [4:0]     wb_dst_sel,
                output reg         wb_mem2reg,
                output reg [1:0]     wb_raddr,
                output reg [2:0]     wb_alu_op,
                //output          wb_branch,
                //output          wb_branch_nxt,
                output reg [31:0]    wb_waddr,
                output reg [3:0]     wb_wstrb,
                output reg [31:0]    wb_wdata
    

);
    
    reg             [31:0]  ex_csr_read;        //should be assigned a value for testing ..changes in writeback stage
    reg             [31:0]  fetch_pc;           //should be assigned a value for testing ..changes in writeback stage
    wire            [31:0]  reg_rdata1;         //should be assigned a value for testing ..changes in writeback stage
    wire            [31:0]  reg_rdata2;         //should be assigned a value for testing ..changes in writeback stage
    

    wire            [32: 0] result_subs;        //Substraction Signed
    wire            [32: 0] result_subu;        //Substraction Unsigned
    reg             [31: 0] result;
    reg             [31: 0] next_pc;
    wire            [31: 0] wr_addr;


    // data memory wires 
    wire[31:0] dmem_waddr ;
    wire[31:0] dmem_raddr ;
    wire dmem_rready;
    wire dmem_wready;
    wire[31:0] dmem_wdata ;
    wire[3:0] dmem_wstrb ;



// Assigning values to Data memory variables 
assign dmem_waddr           = wb_waddr;
assign dmem_raddr           = alu_op1 + ex_imm;
assign dmem_rready          = ex_mem2reg;
assign dmem_wready          = wb_memwr;
assign dmem_wdata           = wb_wdata;
assign dmem_wstrb           = wb_wstrb;




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

/*
    case(1'b1)
        ex_jal   : next_pc = ex_pc + ex_imm;
        ex_jalr  : next_pc = alu_op1 + ex_imm;
        ex_branch: begin
            case(ex_alu_op)
                OP_BEQ : begin
                            next_pc = (result_subs[32: 0] == 'd0) ? ex_pc + ex_imm : fetch_pc + 4;
                            if (result_subs[32: 0] != 'd0) branch_taken = 1'b0;
                         end
                OP_BNE : begin
                            next_pc = (result_subs[32: 0] != 'd0) ? ex_pc + ex_imm : fetch_pc + 4;
                            if (result_subs[32: 0] == 'd0) branch_taken = 1'b0;
                         end
                OP_BLT : begin
                            next_pc = result_subs[32] ? ex_pc + ex_imm : fetch_pc + 4;
                            if (!result_subs[32]) branch_taken = 1'b0;
                         end
                OP_BGE : begin
                            next_pc = !result_subs[32] ? ex_pc + ex_imm : fetch_pc + 4;
                            if (result_subs[32]) branch_taken = 1'b0;
                         end
                OP_BLTU: begin
                            next_pc = result_subu[32] ? ex_pc + ex_imm : fetch_pc + 4;
                            if (!result_subu[32]) branch_taken = 1'b0;
                         end
                OP_BGEU: begin
                            next_pc = !result_subu[32] ? ex_pc + ex_imm : fetch_pc + 4;
                            if (result_subu[32]) branch_taken = 1'b0;
                         end
                default: begin
                         next_pc    = fetch_pc;
                         `ifndef SYNTHESIS
                         $display("Unknown branch instruction");
                         $finish(2);
                         `endif
                         end
            endcase
        end
        default  : begin
                   next_pc          = fetch_pc + 4;
                   branch_taken     = 1'b0;
                   end
    endcase
    */
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

always @(posedge clk or negedge resetb) 
begin
    if (!resetb) 
    begin
        wb_result           <= 32'h0;
        wb_memwr            <= 1'b0;
        wb_alu2reg          <= 1'b0;
        wb_dst_sel          <= 5'h0;
        //wb_branch           <= 1'b0;
        //wb_branch_nxt       <= 1'b0;
        wb_mem2reg          <= 1'b0;
        wb_raddr            <= 2'h0;
        wb_alu_op           <= 3'h0;
    end 

    else 
    // $display("");
    begin
        wb_result           <= result;
        wb_memwr            <= ex_memwr;                //deleted flush value
        wb_alu2reg          <= ex_alu | ex_lui | ex_auipc | ex_jal | ex_jalr | ex_csr | ex_mem2reg;
        wb_dst_sel          <= ex_dst_sel;

        //wb_branch           <= branch_taken;
        //wb_branch_nxt       <= wb_branch;

        wb_mem2reg          <= ex_mem2reg;
        wb_raddr            <= dmem_raddr[1:0];
        wb_alu_op           <= ex_alu_op;
    end
end

//Preparing writeback data for store instruction

always @(posedge clk or negedge resetb) 
begin
    if (!resetb) 
    begin
        wb_waddr            <= 32'h0;
        wb_wstrb            <= 4'h0;
        wb_wdata            <= 32'h0;
    end 
    else if (ex_memwr) 
    begin
        wb_waddr            <= wr_addr;
        case(ex_alu_op)
            OP_SB: begin
                wb_wdata    <= {4{alu_op2[7:0]}};
                case(wr_addr[1:0])
                    2'b00:  wb_wstrb <= 4'b0001;
                    2'b01:  wb_wstrb <= 4'b0010;
                    2'b10:  wb_wstrb <= 4'b0100;
                    default:wb_wstrb <= 4'b1000;
                endcase
            end
            OP_SH: begin
                wb_wdata    <= {2{alu_op2[15:0]}};
                wb_wstrb    <= wr_addr[1] ? 4'b1100 : 4'b0011;
            end
            OP_SW: begin
                wb_wdata    <= alu_op2;
                wb_wstrb    <= 4'hf;
            end
            default: begin
                wb_wdata    <= 32'hx;
                wb_wstrb    <= 4'hx;
            end
        endcase
    end
end
endmodule
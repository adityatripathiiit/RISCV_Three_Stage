////////////////////////////////////////////////////////////
// Stage 2: Execute
////////////////////////////////////////////////////////////

module execute 
    #(
        parameter  [31:0]    RESET   = 32'h0000_0000
    ) 
    (   input clk,
        input reset
    );
//////////////// Including OPCODES ////////////////////////////

`include "opcode.vh"
    
// Selecting the first and second operands of ALU unit

assign pipe.alu_operand1         = pipe.reg_rdata1;                     //First operand gets data from register file
assign pipe.alu_operand2         = (pipe.immediate_sel) ? pipe.execute_immediate : pipe.reg_rdata2;     //Second operand gats data either from immediate or register file
assign pipe.result_subs[32: 0]   = {pipe.alu_operand1[31], pipe.alu_operand1} - {pipe.alu_operand2[31], pipe.alu_operand2};     //Substraction Signed
assign pipe.result_subu[32: 0]   = {1'b0, pipe.alu_operand1} - {1'b0, pipe.alu_operand2};           //Substraction Unsigned
assign pipe.write_address        = pipe.alu_operand1 + pipe.execute_immediate;          //Calculating write address for data memory
assign pipe.branch_stall         = pipe.wb_branch_nxt || pipe.wb_branch;                //Calculating branch stall value

//Calculating next PC value

always @(*) 
begin
    pipe.next_pc      = pipe.fetch_pc + 4;
    pipe.branch_taken = !pipe.branch_stall;
        case(1'b1)
        pipe.jal   : pipe.next_pc = pipe.pc + pipe.execute_immediate;
        pipe.jalr  : pipe.next_pc = pipe.alu_operand1 + pipe.execute_immediate;
        pipe.branch: begin
            case(pipe.alu_operation) 
                BEQ : begin
                            pipe.next_pc = (pipe.result_subs[32: 0] == 'd0) ? pipe.pc + pipe.execute_immediate : pipe.fetch_pc + 4;
                            if (pipe.result_subs[32: 0] != 'd0) 
                                pipe.branch_taken = 1'b0;
                         end
                BNE : begin
                            pipe.next_pc = (pipe.result_subs[32: 0] != 'd0) ? pipe.pc + pipe.execute_immediate : pipe.fetch_pc + 4;
                            if (pipe.result_subs[32: 0] == 'd0) 
                                pipe.branch_taken = 1'b0;
                         end
                BLT : begin
                            pipe.next_pc = pipe.result_subs[32] ? pipe.pc + pipe.execute_immediate : pipe.fetch_pc + 4;
                            if (!pipe.result_subs[32]) 
                                pipe.branch_taken = 1'b0;
                         end
                BGE : begin
                            pipe.next_pc = !pipe.result_subs[32] ? pipe.pc + pipe.execute_immediate : pipe.fetch_pc + 4;
                            if (pipe.result_subs[32]) 
                                pipe.branch_taken = 1'b0;
                         end
                BLTU: begin
                            pipe.next_pc = pipe.result_subu[32] ? pipe.pc + pipe.execute_immediate : pipe.fetch_pc + 4;
                            if (!pipe.result_subu[32]) 
                                pipe.branch_taken = 1'b0;
                         end
                BGEU: begin
                            pipe.next_pc = !pipe.result_subu[32] ? pipe.pc + pipe.execute_immediate : pipe.fetch_pc + 4;
                            if (pipe.result_subu[32]) 
                                pipe.branch_taken = 1'b0;
                         end
                default: begin
                         pipe.next_pc    = pipe.fetch_pc;
                         end
            endcase
        end
        default  : begin
                   pipe.next_pc          = pipe.fetch_pc + 4;
                   pipe.branch_taken     = 1'b0;
                   end
    endcase
end

//Calculating ALU result depending on the opcode

always @(*) 
begin
    case(1'b1)
        pipe.mem_write:   pipe.result          = pipe.alu_operand2;
        pipe.jal:         pipe.result          = pipe.pc + 4;
        pipe.jalr:        pipe.result          = pipe.pc + 4;
        pipe.lui:         pipe.result          = pipe.execute_immediate;
        pipe.alu:
            case(pipe.alu_operation)
                ADD : if (pipe.arithsubtype == 1'b0)
                            pipe.result  = pipe.alu_operand1 + pipe.alu_operand2;
                         else
                            pipe.result  = pipe.alu_operand1 - pipe.alu_operand2;
                SLL : pipe.result     = pipe.alu_operand1 << pipe.alu_operand2;
                SLT : pipe.result     = pipe.result_subs[32] ? 'd1 : 'd0;
                SLTU: pipe.result     = pipe.result_subu[32] ? 'd1 : 'd0;
                XOR : pipe.result     = pipe.alu_operand1 ^ pipe.alu_operand2;
                SR  : if (pipe.arithsubtype == 1'b0)
                            pipe.result  = pipe.alu_operand1 >>> pipe.alu_operand2;
                         else
                            pipe.result  = $signed(pipe.alu_operand1) >>> pipe.alu_operand2;
                OR  : pipe.result     = pipe.alu_operand1 | pipe.alu_operand2;
                AND : pipe.result     = pipe.alu_operand1 & pipe.alu_operand2;
                default: pipe.result     = 'hx;
            endcase
        default: pipe.result = 'hx;
    endcase
end

always @(posedge clk or negedge reset) 
begin
    if (!reset) 
    begin
        pipe.fetch_pc <= RESET;
    end 
    else if (!pipe.stall_read) 
    begin
        pipe.fetch_pc            <= (pipe.branch_stall) ? pipe.fetch_pc + 4 : pipe.next_pc;     //Assigning next PC value
    end
end

//Preparing output for writeback stage

always @(posedge clk or negedge reset) 
begin
    if (!reset) 
    begin
        pipe.wb_result               <= 32'h0;
        pipe.wb_mem_write            <= 1'b0;
        pipe.wb_alu_to_reg           <= 1'b0;
        pipe.wb_dest_reg_sel         <= 5'h0;
        pipe.wb_branch               <= 1'b0;
        pipe.wb_branch_nxt           <= 1'b0;
        pipe.wb_mem_to_reg           <= 1'b0;
        pipe.wb_read_address         <= 2'h0;
        pipe.wb_alu_operation        <= 3'h0;
    end 
    else if (!pipe.stall_read) 
    begin
        pipe.wb_result               <= pipe.result;
        pipe.wb_mem_write            <= pipe.mem_write && !pipe.branch_stall;
        pipe.wb_alu_to_reg           <= pipe.alu | pipe.lui | pipe.jal | pipe.jalr | pipe.mem_to_reg;
        pipe.wb_dest_reg_sel         <= pipe.dest_reg_sel;
        pipe.wb_branch               <= pipe.branch_taken;
        pipe.wb_branch_nxt           <= pipe.wb_branch;
        pipe.wb_mem_to_reg           <= pipe.mem_to_reg;
        pipe.wb_read_address         <= pipe.dmem_read_address[1:0];
        pipe.wb_alu_operation        <= pipe.alu_operation;
    end
end

endmodule
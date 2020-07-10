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

    `include "opcode.vh"
    
    // Selecting the first and second operands of ALU unit


assign pipe.execute_stall             = (pipe.inst_fetch_stall) || (pipe.mem_to_reg && !pipe.dmem_read_valid_checker);

assign pipe.alu_operand1       = pipe.reg_rdata1;
assign pipe.alu_operand2       = (pipe.immediate_sel) ? pipe.execute_immediate : pipe.reg_rdata2;

assign pipe.result_subs[32: 0]   = {pipe.alu_operand1[31], pipe.alu_operand1} - {pipe.alu_operand2[31], pipe.alu_operand2};
assign pipe.result_subu[32: 0]   = {1'b0, pipe.alu_operand1} - {1'b0, pipe.alu_operand2};
assign pipe.write_address              = pipe.alu_operand1 + pipe.execute_immediate;

assign pipe.branch_stall     = pipe.wb_branch_nxt || pipe.wb_branch;


//Calculating next pc value

always @(*) 

begin
    // $monitor("time: %t , dmem_read_valid =%h",$time, dmem_read_valid);
    pipe.next_pc      = pipe.fetch_pc + 4;
    pipe.branch_taken = !pipe.branch_stall;
        case(1'b1)
        pipe.jal   : pipe.next_pc = pipe.pc + pipe.execute_immediate;
        pipe.jalr  : pipe.next_pc = pipe.alu_operand1 + pipe.execute_immediate;
        pipe.branch: begin
            case(pipe.alu_operation) 
                BEQ : begin
                            pipe.next_pc = (pipe.result_subs[32: 0] == 'd0) ? pipe.pc + pipe.execute_immediate : pipe.fetch_pc + 4;
                            if (pipe.result_subs[32: 0] != 'd0) pipe.branch_taken = 1'b0;
                         end
                BNE : begin
                            pipe.next_pc = (pipe.result_subs[32: 0] != 'd0) ? pipe.pc + pipe.execute_immediate : pipe.fetch_pc + 4;
                            if (pipe.result_subs[32: 0] == 'd0) pipe.branch_taken = 1'b0;
                         end
                BLT : begin
                            pipe.next_pc = pipe.result_subs[32] ? pipe.pc + pipe.execute_immediate : pipe.fetch_pc + 4;
                            if (!pipe.result_subs[32]) pipe.branch_taken = 1'b0;
                         end
                BGE : begin
                            pipe.next_pc = !pipe.result_subs[32] ? pipe.pc + pipe.execute_immediate : pipe.fetch_pc + 4;
                            if (pipe.result_subs[32]) pipe.branch_taken = 1'b0;
                         end
                BLTU: begin
                            pipe.next_pc = pipe.result_subu[32] ? pipe.pc + pipe.execute_immediate : pipe.fetch_pc + 4;
                            if (!pipe.result_subu[32]) pipe.branch_taken = 1'b0;
                         end
                BGEU: begin
                            pipe.next_pc = !pipe.result_subu[32] ? pipe.pc + pipe.execute_immediate : pipe.fetch_pc + 4;
                            if (pipe.result_subu[32]) pipe.branch_taken = 1'b0;
                         end
                default: begin
                         pipe.next_pc    = pipe.fetch_pc;
                        
                        //  $display("Unknown branch instruction");
                        //  $finish(2);
                        
                         end
            endcase
        end
        default  : begin
                   pipe.next_pc          = pipe.fetch_pc + 4;
                   pipe.branch_taken     = 1'b0;
                   end
    endcase
end

//Calculating result depending on the opcode

always @(*) 
begin
    case(1'b1)
        pipe.mem_write:   pipe.result          = pipe.alu_operand2;
        pipe.jal:     pipe.result          = pipe.pc + 4;
        pipe.jalr:    pipe.result          = pipe.pc + 4;
        pipe.lui:     pipe.result          = pipe.execute_immediate;

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

//Preparing output for writeback stage

always @(posedge clk or negedge reset) 
begin
    if (!reset) 
    begin
        pipe.fetch_pc <= RESET;
    end 
    else if (!pipe.stall_read && !pipe.execute_stall) begin
        pipe.fetch_pc            <= (pipe.branch_stall) ? pipe.fetch_pc + 4 : pipe.next_pc;
    end
end


always @(posedge clk or negedge reset) begin
    if (!reset) begin
        pipe.wb_result           <= 32'h0;
        pipe.wb_mem_write            <= 1'b0;
        pipe.wb_alu_to_reg          <= 1'b0;
        pipe.wb_dest_reg_sel          <= 5'h0;
        pipe.wb_branch           <= 1'b0;
        pipe.wb_branch_nxt       <= 1'b0;
        pipe.wb_mem_to_reg          <= 1'b0;
        pipe.wb_read_address            <= 2'h0;
        pipe.wb_alu_operation           <= 3'h0;
    end else if (!pipe.execute_stall && !pipe.stall_read) begin
        pipe.wb_result           <= pipe.result;
        pipe.wb_mem_write            <= pipe.mem_write && !pipe.branch_stall;
        pipe.wb_alu_to_reg          <= pipe.alu | pipe.lui | pipe.jal | pipe.jalr | pipe.mem_to_reg;
        pipe.wb_dest_reg_sel          <= pipe.dest_reg_sel;
        pipe.wb_branch           <= pipe.branch_taken;
        pipe.wb_branch_nxt       <= pipe.wb_branch;
        pipe.wb_mem_to_reg          <= pipe.mem_to_reg;
        pipe.wb_read_address            <= pipe.dmem_read_address[1:0];
        pipe.wb_alu_operation           <= pipe.alu_operation;
    end
end


always @(posedge clk or negedge reset) begin
    if (!reset) begin
        pipe.wb_write_address            <= 32'h0;
        pipe.wb_write_byte            <= 4'h0;
        pipe.wb_write_data            <= 32'h0;
    end else if (!pipe.execute_stall && !pipe.stall_read && pipe.mem_write) begin
    //$display("time: %t , wb_dest_reg_sel=%d",$time, write_address);
    //$display("time: %t , src1_select=%d",$time, src1_select);
        pipe.wb_write_address            <= pipe.write_address;
        case(pipe.alu_operation)
            SB: begin
                pipe.wb_write_data    <= {4{pipe.alu_operand2[7:0]}};
                case(pipe.write_address[1:0])
                    2'b00:  pipe.wb_write_byte <= 4'b0001;
                    2'b01:  pipe.wb_write_byte <= 4'b0010;
                    2'b10:  pipe.wb_write_byte <= 4'b0100;
                    default:pipe.wb_write_byte <= 4'b1000;
                endcase
            end
            SH: begin
                pipe.wb_write_data    <= {2{pipe.alu_operand2[15:0]}};
                pipe.wb_write_byte    <= pipe.write_address[1] ? 4'b1100 : 4'b0011;
            end
            SW: begin
                pipe.wb_write_data    <= pipe.alu_operand2;
                pipe.wb_write_byte    <= 4'hf;
            end
            default: begin
                pipe.wb_write_data    <= 32'hx;
                pipe.wb_write_byte    <= 4'hx;
            end
        endcase
    end
end

endmodule
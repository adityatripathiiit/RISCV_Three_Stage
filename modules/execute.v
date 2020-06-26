////////////////////////////////////////////////////////////
// Stage 2: Execute
////////////////////////////////////////////////////////////

module execute 
 #(
                    parameter  [31:0]    RESET   = 32'h0000_0000
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
                input [4:0]     dest_reg_sel ,
                input           dmem_read_valid  
             );

    `include "opcode.vh"
    
    reg             [31:0]  fetch_pc ;           
    wire            [31:0]  reg_rdata1 ;         
    wire            [31:0]  reg_rdata2 ;         
    

    wire            [32: 0] result_subs;        //Substraction Signed
    wire            [32: 0] result_subu;        //Substraction Unsigned
    reg             [31: 0] result;
    reg             [31: 0] next_pc;
    wire            [31: 0] write_address;

    reg                     branch_taken;
    wire                     branch_stall;
    wire                    stall;

    // write back 
    reg                     wb_alu_to_reg;
    reg             [31: 0] wb_result;
    reg             [ 2: 0] wb_alu_operation;
    reg                     wb_mem_write;
    reg                     wb_mem_to_reg;
    reg             [ 4: 0] wb_dest_reg_sel;
    reg                     wb_branch;
    reg                     wb_branch_nxt;
    reg             [31: 0] wb_write_address;
    reg             [ 1: 0] wb_read_address;
    reg             [ 3: 0] wb_write_byte;
    reg             [31: 0] wb_write_data;

// Selecting the first and second operands of ALU unit
wire[31:0] alu_operand1;
wire[31:0] alu_operand2;

assign stall             = (IF_ID.inst_fetch_stall) || (mem_to_reg && !dmem_read_valid);

assign alu_operand1       = reg_rdata1;
assign alu_operand2       = (immediate_sel) ? immediate : reg_rdata2;

assign result_subs[32: 0]   = {alu_operand1[31], alu_operand1} - {alu_operand2[31], alu_operand2};
assign result_subu[32: 0]   = {1'b0, alu_operand1} - {1'b0, alu_operand2};
assign write_address              = alu_operand1 + immediate;

assign branch_stall     = wb_branch_nxt || wb_branch;


//Calculating next pc value

always @(*) 
begin
    next_pc      = fetch_pc + 4;
    branch_taken = !branch_stall;
        case(1'b1)
        jal   : next_pc = pc + immediate;
        jalr  : next_pc = alu_operand1 + immediate;
        IF_ID.branch: begin
            case(alu_operation) 
                BEQ : begin
                            next_pc = (result_subs[32: 0] == 'd0) ? pc + immediate : fetch_pc + 4;
                            if (result_subs[32: 0] != 'd0) branch_taken = 1'b0;
                         end
                BNE : begin
                            next_pc = (result_subs[32: 0] != 'd0) ? pc + immediate : fetch_pc + 4;
                            if (result_subs[32: 0] == 'd0) branch_taken = 1'b0;
                         end
                BLT : begin
                            next_pc = result_subs[32] ? pc + immediate : fetch_pc + 4;
                            if (!result_subs[32]) branch_taken = 1'b0;
                         end
                BGE : begin
                            next_pc = !result_subs[32] ? pc + immediate : fetch_pc + 4;
                            if (result_subs[32]) branch_taken = 1'b0;
                         end
                BLTU: begin
                            next_pc = result_subu[32] ? pc + immediate : fetch_pc + 4;
                            if (!result_subu[32]) branch_taken = 1'b0;
                         end
                BGEU: begin
                            next_pc = !result_subu[32] ? pc + immediate : fetch_pc + 4;
                            if (result_subu[32]) branch_taken = 1'b0;
                         end
                default: begin
                         next_pc    = fetch_pc;
                        
                        //  $display("Unknown branch instruction");
                        //  $finish(2);
                        
                         end
            endcase
        end
        default  : begin
                   next_pc          = fetch_pc + 4;
                   branch_taken     = 1'b0;
                   end
    endcase
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
    else if (!IF_ID.stall_read && !stall) begin
        fetch_pc            <= (branch_stall) ? fetch_pc + 4 : next_pc;
    end
end


always @(posedge clk or negedge reset) begin
    if (!reset) begin
        wb_result           <= 32'h0;
        wb_mem_write            <= 1'b0;
        wb_alu_to_reg          <= 1'b0;
        wb_dest_reg_sel          <= 5'h0;
        wb_branch           <= 1'b0;
        wb_branch_nxt       <= 1'b0;
        wb_mem_to_reg          <= 1'b0;
        wb_read_address            <= 2'h0;
        wb_alu_operation           <= 3'h0;
    end else if (!stall && !IF_ID.stall_read) begin
        wb_result           <= result;
        wb_mem_write            <= mem_write && !branch_stall;
        wb_alu_to_reg          <= alu | lui | jal | jalr | mem_to_reg;
        wb_dest_reg_sel          <= dest_reg_sel;
        wb_branch           <= branch_taken;
        wb_branch_nxt       <= wb_branch;
        wb_mem_to_reg          <= mem_to_reg;
        wb_read_address            <= wb.dmem_read_address[1:0];
        wb_alu_operation           <= alu_operation;
    end
end


always @(posedge clk or negedge reset) begin
    if (!reset) begin
        wb_write_address            <= 32'h0;
        wb_write_byte            <= 4'h0;
        wb_write_data            <= 32'h0;
    end else if (!stall && !IF_ID.stall_read && mem_write) begin
        wb_write_address            <= write_address;
        case(alu_operation)
            SB: begin
                wb_write_data    <= {4{alu_operand2[7:0]}};
                case(write_address[1:0])
                    2'b00:  wb_write_byte <= 4'b0001;
                    2'b01:  wb_write_byte <= 4'b0010;
                    2'b10:  wb_write_byte <= 4'b0100;
                    default:wb_write_byte <= 4'b1000;
                endcase
            end
            SH: begin
                wb_write_data    <= {2{alu_operand2[15:0]}};
                wb_write_byte    <= write_address[1] ? 4'b1100 : 4'b0011;
            end
            SW: begin
                wb_write_data    <= alu_operand2;
                wb_write_byte    <= 4'hf;
            end
            default: begin
                wb_write_data    <= 32'hx;
                wb_write_byte    <= 4'hx;
            end
        endcase
    end
end

endmodule
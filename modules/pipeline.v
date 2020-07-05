
module pipeline 
#(
        parameter [31:0]             RESET = 32'h0000_0000
)

    (
    input                   clk,
    input                   reset,
    input                   stall,
    output reg              exception,  

    // interface of instruction Memory
    input                   inst_mem_is_valid,
    input           [31: 0] inst_mem_read_data,
    output                  inst_mem_is_ready,
    output          [31: 0] inst_mem_address,

    input           [31: 0] dmem_read_data,
    input                   dmem_write_valid,
    input                   dmem_read_valid,
    output                  dmem_write_ready,
    output                  dmem_read_ready,
    output          [31: 0] dmem_write_address,
    output          [31: 0] dmem_read_address,
    output          [31: 0] dmem_write_data,
    output          [ 3: 0] dmem_write_byte
);

`include "opcode.vh"
// General wires  (for passing opcode and other values to ALU)

reg             [31: 0] immediate;
reg                     immediate_sel;
reg             [ 4: 0] src1_select;
reg             [ 4: 0] src2_select;
reg             [ 4: 0] dest_reg_sel;
reg             [ 2: 0] alu_operation;
reg                     arithsubtype;
reg                     mem_write;
reg                     mem_to_reg;
reg                     illegal_inst;
reg             [31: 0] execute_immediate;
reg                     alu;
reg                     lui;
reg                     jal;
reg                     jalr;
reg                     branch;
reg                     stall_read;
wire             [31:0] instruction;
// pc wires

reg             [31: 0] pc;
reg             [31: 0] inst_fetch_pc;

//stalls
wire                    inst_fetch_stall;
reg                     flush;


reg             [31:0]  fetch_pc ;           
//wire            [31:0]  Iwb.reg_rdata1 ;         
wire            [31:0]  reg_rdata2 ;         


wire            [32: 0] result_subs;        //Substraction Signed
wire            [32: 0] result_subu;        //Substraction Unsigned
reg             [31: 0] result;
reg             [31: 0] next_pc;
wire            [31: 0] write_address;

reg                     branch_taken;
wire                     branch_stall;

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

wire                    execute_stall;
// Wire declarations end

//  initial inst_fetch_pc = 0;

// reading the instructions and assigning them to instruction variable

////////////////////////////////////////////////////////////////
// IF stage 
////////////////////////////////////////////////////////////////
assign instruction                 = flush? NOP:inst_mem_read_data;
////////////////////////////////
assign dmem_write_address           = wb_write_address;
assign dmem_read_address            = alu_operand1 + execute_immediate;
assign dmem_read_ready              = mem_to_reg;
assign dmem_write_ready             = wb_mem_write;
assign dmem_write_data              = wb_write_data;
assign dmem_write_byte              = wb_write_byte;

// check for illegal instruction(instruction not in RV-32I architecture)

assign inst_fetch_stall = !inst_mem_is_valid;

always @(posedge clk or negedge reset) begin
    if (!reset)
        exception           <= 1'b0;
        
    else if (illegal_inst || inst_mem_address[1:0] != 0)
        exception           <= 1'b1;
end

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        stall_read             <= 1'b1;
        flush               <= 1'b1;
    end else begin
        stall_read             <= stall;
        flush               <= stall_read;
    end
end

////////////////////////////////////////////////////////////////
// IF stage end
////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////
// ID stage 
////////////////////////////////////////////////////////////////

always @* begin
    immediate                     = 32'h0;
    illegal_inst                  = 1'b0;
    case(instruction[`OPCODE])
        JALR  : immediate      = {{20{instruction[31]}}, instruction[31:20]}; // I-Type 
        BRANCH: immediate      = {{20{instruction[31]}}, instruction[8], instruction[30:25], instruction[11:9], 1'b0}; // B-type
        LOAD  : immediate      = {{20{instruction[31]}}, instruction[31:20]}; // I-type
        STORE : immediate      = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; // S-type
        ARITHI: immediate      = (instruction[`FUNC3] == SLL || instruction[`FUNC3] == SR) ? {27'h0, instruction[24:20]} : {{20{instruction[31]}}, instruction[31:20]}; // I-type
        ARITHR: immediate      = 'd0; // R-type
        LUI   : immediate      = {instruction[31:12], 12'd0}; // U-type
        JAL   : immediate      = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // J-type
        default: begin // illegal instruction
            illegal_inst    = 1'b1;
        end
    endcase
end

always @(posedge clk or negedge reset) begin

    // If reset of the system is performed, reset all the values. 

    if (!reset) begin
        execute_immediate      <= 32'h0;
        immediate_sel          <= 1'b0;
        alu                    <= 1'b0;
        jal                    <= 1'b0;
        jalr                   <= 1'b0;
        branch                 <= 1'b0;
        pc                     <= RESET;
        src1_select            <= 5'h0;
        src2_select            <= 5'h0;
        dest_reg_sel           <= 5'h0;
        alu_operation          <= 3'h0;
        arithsubtype           <= 1'b0;
        mem_write              <= 1'b0;
        mem_to_reg             <= 1'b0;
    end else if(!stall_read && !inst_fetch_stall) begin                      // else take the values from the IF stage and decode it to pass values to corresponding wires
        execute_immediate      <= immediate;
        immediate_sel          <= (instruction[`OPCODE] == JALR  ) ||
                               (instruction[`OPCODE] == LOAD  ) ||
                               (instruction[`OPCODE] == ARITHI);
        alu                    <= (instruction[`OPCODE] == ARITHI) ||
                               (instruction[`OPCODE] == ARITHR);
        lui                    <= instruction[`OPCODE] == LUI;
        jal                    <= instruction[`OPCODE] == JAL;
        jalr                   <= instruction[`OPCODE] == JALR;
        branch                 <= instruction[`OPCODE] == BRANCH;
        pc                     <= inst_fetch_pc;
        src1_select            <= instruction[`RS1];
        src2_select            <= instruction[`RS2];
        dest_reg_sel           <= instruction[`RD];
        alu_operation          <= instruction[`FUNC3];
        arithsubtype           <= instruction[`SUBTYPE] && !(instruction[`OPCODE] == ARITHI && instruction[`FUNC3] == ADD);
        mem_write              <= instruction[`OPCODE] == STORE;
        mem_to_reg             <= instruction[`OPCODE] == LOAD;
        
    end
    
end




////////////////////////////////////////////////////////////
// Stage 2: Execute
////////////////////////////////////////////////////////////


    
assign execute_stall             = (inst_fetch_stall) || (mem_to_reg);

assign alu_operand1       = reg_rdata1;
assign alu_operand2       = (immediate_sel) ? execute_immediate : reg_rdata2;

assign result_subs[32: 0]   = {alu_operand1[31], alu_operand1} - {alu_operand2[31], alu_operand2};
assign result_subu[32: 0]   = {1'b0, alu_operand1} - {1'b0, alu_operand2};
assign write_address              = alu_operand1 + execute_immediate;

assign branch_stall     = wb_branch;


//Calculating next pc value

always @(*) 

begin
    // $monitor("time: %t , dmem_read_valid =%h",$time, dmem_read_valid);
    next_pc      = fetch_pc + 4;
    branch_taken = !branch_stall;
        case(1'b1)
        jal   : next_pc = pc + execute_immediate;
        jalr  : next_pc = alu_operand1 + execute_immediate;
        branch: begin
            case(alu_operation) 
                BEQ : begin
                            next_pc = (result_subs[31: 0] == 'd0) ? pc + execute_immediate : fetch_pc + 4;
                            if (result_subs[31: 0] != 'd0) branch_taken = 1'b0;
                         end
                BNE : begin
                            next_pc = (result_subs[31: 0] != 'd0) ? pc + execute_immediate : fetch_pc + 4;
                            if (result_subs[31: 0] == 'd0) branch_taken = 1'b0;
                         end
                BLT : begin
                            next_pc = result_subs[31] ? pc + execute_immediate : fetch_pc + 4;
                            if (!result_subs[31]) branch_taken = 1'b0;
                         end
                BGE : begin
                            next_pc = result_subs[31] ?  fetch_pc + 4 : pc + execute_immediate;
                            if (!result_subs[31]) branch_taken = 1'b0;
                         end
                BLTU: begin
                            next_pc = result_subu[31] ? pc + execute_immediate : fetch_pc + 4;
                            if (!result_subu[31]) branch_taken = 1'b0;
                         end
                BGEU: begin
                            next_pc = !result_subu[31] ? pc + execute_immediate : fetch_pc + 4;
                            if (result_subu[31]) branch_taken = 1'b0;
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
        lui:     result          = execute_immediate;

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
    else if (!stall_read && !execute_stall) begin
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
    end else if (!execute_stall && !stall_read) begin
        wb_result           <= result;
        wb_mem_write            <= mem_write && !branch_stall;
        wb_alu_to_reg          <= alu | lui | jal | jalr | mem_to_reg;
        wb_dest_reg_sel          <= dest_reg_sel;
        wb_branch           <= branch_taken;
        wb_branch_nxt       <= wb_branch;
        wb_mem_to_reg          <= mem_to_reg;
        wb_read_address            <= dmem_read_address[1:0];
        wb_alu_operation           <= alu_operation;
    end
end


always @(posedge clk or negedge reset) begin
    if (!reset) begin
        wb_write_address            <= 32'h0;
        wb_write_byte            <= 4'h0;
        wb_write_data            <= 32'h0;
    end else if (!execute_stall && !stall_read && mem_write) begin
    //$display("time: %t , wb_dest_reg_sel=%d",$time, write_address);
    //$display("time: %t , src1_select=%d",$time, src1_select);
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



// stage 3: write back
////////////////////////////////////////////////////////////

reg [31: 0] wb_read_data;
reg wb_nop;
reg wb_nop_more;
wire [31: 0] reg_rdata1;
reg [31: 0] regs [31: 1];

wire    wb_stall;
wire    wb_nop_stall;

assign inst_mem_address           = fetch_pc;
assign inst_mem_is_ready           = !stall_read && !wb_stall;
assign wb_stall             = execute_stall || (wb_mem_to_reg && !dmem_write_valid);
assign wb_nop_stall             = wb_nop || wb_nop_more;




always @(posedge clk or negedge reset) begin
    if (!reset) begin
        inst_fetch_pc <= RESET;
    end
    else if (!stall_read && !wb_stall) begin
        inst_fetch_pc               <= fetch_pc;
    end
end


// initial
// begin
// $monitor("reg=%d",regs[0]);
// end


always @(posedge clk or negedge reset) begin
    if (!reset) begin
        wb_nop              <= 1'b0;
        wb_nop_more         <= 1'b0;
    end else if (!stall_read && !(execute_stall || (wb_mem_to_reg && !dmem_write_valid))) begin
        wb_nop              <= wb_branch;
        wb_nop_more         <= wb_nop;
    end
end

always @* begin
    case(wb_alu_operation)
        LB  : begin
                    case(wb_read_address[1:0])
                        2'b00: wb_read_data[31: 0] = {{24{dmem_read_data[7]}}, dmem_read_data[7:0]};
                        2'b01: wb_read_data[31: 0] = {{24{dmem_read_data[15]}}, dmem_read_data[15:8]};
                        2'b10: wb_read_data[31: 0] = {{24{dmem_read_data[23]}}, dmem_read_data[23:16]};
                        2'b11: wb_read_data[31: 0] = {{24{dmem_read_data[31]}}, dmem_read_data[31:24]};
                    endcase
                 end
        LH  : wb_read_data = (wb_read_address[1]) ? {{16{dmem_read_data[31]}}, dmem_read_data[31:16]} : {{16{dmem_read_data[15]}}, dmem_read_data[15:0]};
        LW  : wb_read_data = dmem_read_data;
        LBU : begin
                    case(wb_read_address[1:0])
                        2'b00: wb_read_data[31: 0] = {24'h0, dmem_read_data[7:0]};
                        2'b01: wb_read_data[31: 0] = {24'h0, dmem_read_data[15:8]};
                        2'b10: wb_read_data[31: 0] = {24'h0, dmem_read_data[23:16]};
                        2'b11: wb_read_data[31: 0] = {24'h0, dmem_read_data[31:24]};
                    endcase
                 end
        LHU : wb_read_data = (wb_read_address[1]) ? {16'h0, dmem_read_data[31:16]} : {16'h0, dmem_read_data[15:0]};
        default: wb_read_data = 'hx;
    endcase
end

////////////////////////////////////////////////////////////
// Register file
////////////////////////////////////////////////////////////
wire temp;
assign temp = !wb_nop_stall && wb_alu_to_reg && (wb_dest_reg_sel == src1_select);

assign reg_rdata1[31: 0] = (src1_select == 5'h0) ? 32'h0 :
                        (!wb_nop_stall && wb_alu_to_reg && (wb_dest_reg_sel == src1_select)) ? (wb_mem_to_reg ? wb_read_data : wb_result) :
                        regs[src1_select];
assign reg_rdata2[31: 0] = (src2_select == 5'h0) ? 32'h0 :
                        (!wb_nop_stall && wb_alu_to_reg && (wb_dest_reg_sel == src2_select)) ? (wb_mem_to_reg ? wb_read_data : wb_result) :
                        regs[src2_select];

integer i;
always @(posedge clk or negedge reset) begin
    if (!reset) begin
        for(i = 1; i < 32; i=i+1) begin
            regs[i] <= 32'h0;
        end
    end else if (wb_alu_to_reg && !stall_read && !(wb_stall || wb_nop_stall)) begin
        // $display("hello");
        regs[wb_dest_reg_sel]    <= wb_mem_to_reg ? wb_read_data : wb_result;
    end
end

endmodule
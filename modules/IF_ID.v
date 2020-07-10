////////////////////////////////////////////////////////////
// stage 1: fetch/decode
////////////////////////////////////////////////////////////
module IF_ID 
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
    input           [31: 0] inst_mem_read_data
    
    );

//////////////// Including OPCODES ////////////////////////////
`include "opcode.vh"


////////////////////////////////////////////////////////////////
// IF stage Start
////////////////////////////////////////////////////////////////
assign pipe.instruction                 = pipe.stall_read? NOP:inst_mem_read_data;


// check for illegal instruction(instruction not in RV-32I architecture)

always @(posedge clk or negedge reset) 
begin
    if (!reset)
        exception           <= 1'b0;
        
    else if (pipe.illegal_inst || pipe.inst_mem_address[1:0] != 0)
        exception           <= 1'b1;
end


// Stall read assignment for stalling while reading 

always @(posedge clk or negedge reset) 
begin
    if (!reset) 
    begin
        pipe.stall_read             <= 1'b1;
    end else 
    begin
        pipe.stall_read             <= stall;
    end
end

////////////////////////////////////////////////////////////////
// IF stage end
////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////
// ID stage 
////////////////////////////////////////////////////////////////

always @* 
begin
    pipe.immediate                     = 32'h0;
    pipe.illegal_inst                  = 1'b0;
    case(pipe.instruction[`OPCODE])
        JALR  : pipe.immediate      = {{20{pipe.instruction[31]}}, pipe.instruction[31:20]}; // I-Type 
        BRANCH: pipe.immediate      = {{20{pipe.instruction[31]}}, pipe.instruction[7], pipe.instruction[30:25], pipe.instruction[11:8], 1'b0}; // B-type
        LOAD  : pipe.immediate      = {{20{pipe.instruction[31]}}, pipe.instruction[31:20]}; // I-type
        STORE : pipe.immediate      = {{20{pipe.instruction[31]}}, pipe.instruction[31:25], pipe.instruction[11:7]}; // S-type
        ARITHI: pipe.immediate      = (pipe.instruction[`FUNC3] == SLL || pipe.instruction[`FUNC3] == SR) ? {27'h0, pipe.instruction[24:20]} : {{20{pipe.instruction[31]}}, pipe.instruction[31:20]}; // I-type
        ARITHR: pipe.immediate      = 'd0; // R-type
        LUI   : pipe.immediate      = {pipe.instruction[31:12], 12'd0}; // U-type
        JAL   : pipe.immediate      = {{12{pipe.instruction[31]}}, pipe.instruction[19:12], pipe.instruction[20], pipe.instruction[30:21], 1'b0}; // J-type
        default: begin // illegal instruction
            pipe.illegal_inst    = 1'b1;
        end
    endcase
end

always @(posedge clk or negedge reset) 
begin

    // If reset of the system is performed, reset all the values. 

    if (!reset) 
    begin
        pipe.execute_immediate      <= 32'h0;
        pipe.immediate_sel          <= 1'b0;
        pipe.alu                    <= 1'b0;
        pipe.jal                    <= 1'b0;
        pipe.jalr                   <= 1'b0;
        pipe.branch                 <= 1'b0;
        pipe.pc                     <= RESET;
        pipe.src1_select            <= 5'h0;
        pipe.src2_select            <= 5'h0;
        pipe.dest_reg_sel           <= 5'h0;
        pipe.alu_operation          <= 3'h0;
        pipe.arithsubtype           <= 1'b0;
        pipe.mem_write              <= 1'b0;
        pipe.mem_to_reg             <= 1'b0;
    end 
    else if(!pipe.stall_read) 
    begin                      // else take the values from the IF stage and decode it to pass values to corresponding wires
        pipe.execute_immediate      <= pipe.immediate;
        pipe.immediate_sel          <= (pipe.instruction[`OPCODE] == JALR  ) || (pipe.instruction[`OPCODE] == LOAD  ) ||
                                        (pipe.instruction[`OPCODE] == ARITHI);
        pipe.alu                    <= (pipe.instruction[`OPCODE] == ARITHI) || (pipe.instruction[`OPCODE] == ARITHR);
        pipe.lui                    <= pipe.instruction[`OPCODE] == LUI;
        pipe.jal                    <= pipe.instruction[`OPCODE] == JAL;
        pipe.jalr                   <= pipe.instruction[`OPCODE] == JALR;
        pipe.branch                 <= pipe.instruction[`OPCODE] == BRANCH;
        pipe.pc                     <= pipe.inst_fetch_pc;
        pipe.src1_select            <= pipe.instruction[`RS1];
        pipe.src2_select            <= pipe.instruction[`RS2];
        pipe.dest_reg_sel           <= pipe.instruction[`RD];
        pipe.alu_operation          <= pipe.instruction[`FUNC3];
        pipe.arithsubtype           <= pipe.instruction[`SUBTYPE] && !(pipe.instruction[`OPCODE] == ARITHI && pipe.instruction[`FUNC3] == ADD);
        pipe.mem_write              <= pipe.instruction[`OPCODE] == STORE;
        pipe.mem_to_reg             <= pipe.instruction[`OPCODE] == LOAD;
        
    end
    
end



// Data forwarding and storing data in respective registers depending on conditions of write stalls, and other conditions 

assign pipe.reg_rdata1[31: 0] = (pipe.src1_select == 5'h0) ? 32'h0 :
                        (!pipe.wb_stall && pipe.wb_alu_to_reg && (pipe.wb_dest_reg_sel == pipe.src1_select)) ? (pipe.wb_mem_to_reg ? pipe.wb_read_data : pipe.wb_result) :
                        pipe.regs[pipe.src1_select];
assign pipe.reg_rdata2[31: 0] = (pipe.src2_select == 5'h0) ? 32'h0 :
                        (!pipe.wb_stall && pipe.wb_alu_to_reg && (pipe.wb_dest_reg_sel == pipe.src2_select)) ? (pipe.wb_mem_to_reg ? pipe.wb_read_data : pipe.wb_result) :
                        pipe.regs[pipe.src2_select];


////////////////////////////////////////////////////////////
// Register file
////////////////////////////////////////////////////////////

integer i;
always @(posedge clk or negedge reset) 
begin
    if (!reset) 
    begin
        for(i = 1; i < 32; i=i+1) 
        begin
            pipe.regs[i] <= 32'h0;
        end
    end 
    else if (pipe.wb_alu_to_reg && !pipe.stall_read && !(pipe.wb_stall)) 
    begin
        pipe.regs[pipe.wb_dest_reg_sel]    <= pipe.wb_mem_to_reg ? pipe.wb_read_data : pipe.wb_result;
    end
end




endmodule

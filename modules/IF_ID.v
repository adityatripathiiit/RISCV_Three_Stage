// stage 1: fetch/decode
////////////////////////////////////////////////////////////



module IF_ID 
#(
        parameter [31:0]             RESET = 32'h0000_0000
)

    (
    input                   clk,
    input                   reset,
    output reg              exception,  

    // interface of instruction Memory
    input                   inst_mem_is_valid,
    input           [31: 0] inst_mem_read_data,
    output                  inst_mem_is_ready,
    output          [31: 0] inst_mem_addr
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
wire             [31:0] instruction;

// pc wires
reg             [31: 0] inst_fetch_pc;
reg             [31: 0] pc;

//stalls
wire                    inst_fetch_stall;

// Wire declarations end

initial inst_fetch_pc = 0;

// reading the instructions and assigning them to instruction variable

////////////////////////////////////////////////////////////////
// IF stage 
////////////////////////////////////////////////////////////////
assign instruction                 =  inst_mem_read_data;

// check for illegal instruction(instruction not in RV-32I architecture)

assign inst_fetch_stall = !inst_mem_is_valid;

always @(posedge clk or negedge reset) begin
    if (!reset)
        exception           <= 1'b0;
    else if (illegal_inst || inst_mem_addr[1:0] != 0)
        exception           <= 1'b1;
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
        BRANCH: immediate      = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type
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
        immediate              <= 32'h0;
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
    end else if(!inst_fetch_stall) begin                      // else take the values from the IF stage and decode it to pass values to corresponding wires
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
    inst_fetch_pc <= inst_fetch_pc+4;
end

endmodule

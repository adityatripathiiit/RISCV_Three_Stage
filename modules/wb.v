// stage 3: write back
////////////////////////////////////////////////////////////

module wb #(
            parameter  [31:0]    RESET   = 32'h0000_0000
            )
    (
    input clk,
    input reset,

    input           [1:0]   wb_read_address,
    input                   wb_branch,
    input           [4:0]   src1_select,
    input           [4:0]   src2_select,
    input                   wb_alu_to_reg,
    input           [4:0]   wb_dest_reg_sel,
    input           [31: 0] wb_result,
    input                   wb_mem_to_reg,
    input           [2:0]   wb_alu_operation,
    output                  dmem_write_ready,
    output                  dmem_read_ready,
    input           [31: 0] dmem_read_data,
    input                   dmem_write_valid,
    input                   dmem_read_valid,
    output          [31: 0] dmem_write_address,
    output          [31: 0] dmem_read_address,
    output          [31: 0] dmem_write_data,
    output          [ 3: 0] dmem_write_byte
);

`include "opcode.vh"


reg [31: 0] wb_read_data;
reg wb_nop;
reg wb_nop_more;
wire [31: 0] reg_rdata1, reg_rdata2;
reg [31: 0] regs [31: 1];

wire    wb_stall;
wire    wb_nop_stall;

assign IF_ID.inst_mem_address           = execute.fetch_pc;
assign IF_ID.inst_mem_is_ready           = !IF_ID.stall_read && !wb_stall;
assign wb_stall             = execute.stall || (execute.wb_mem_to_reg && !dmem_write_valid);
assign wb_nop_stall             = wb_nop || wb_nop_more;

////////////////////////////////
assign dmem_write_address           = execute.wb_write_address;
assign dmem_read_address           = execute.alu_operand1 + execute.immediate;
assign dmem_read_ready          = execute.mem_to_reg;
assign dmem_write_ready          = execute.wb_mem_write;
assign dmem_write_data           = execute.wb_write_data;
assign dmem_write_byte           = execute.wb_write_byte;


always @(posedge clk or negedge reset) begin
    if (!reset) begin
        IF_ID.inst_fetch_pc <= RESET;
    end
    else if (!IF_ID.stall_read && !wb_stall) begin
        IF_ID.inst_fetch_pc               <= execute.fetch_pc;
    end
end


// initial
// begin
// $monitor("reg=%d",regs[4]);
// end


always @(posedge clk or negedge reset) begin
    if (!reset) begin
        wb_nop              <= 1'b0;
        wb_nop_more         <= 1'b0;
    end else if (!IF_ID.stall_read && !(execute.stall || (execute.wb_mem_to_reg && !dmem_write_valid))) begin
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

assign execute.reg_rdata1[31: 0] = (src1_select == 5'h0) ? 32'h0 :
                        (!wb_nop_stall && wb_alu_to_reg && (wb_dest_reg_sel == src1_select)) ? (wb_mem_to_reg ? wb_read_data : wb_result) :
                        regs[src1_select];
assign execute.reg_rdata2[31: 0] = (src2_select == 5'h0) ? 32'h0 :
                        (!wb_nop_stall && wb_alu_to_reg && (wb_dest_reg_sel == src2_select)) ? (wb_mem_to_reg ? wb_read_data : wb_result) :
                        regs[src2_select];

integer i;
always @(posedge clk or negedge reset) begin
    if (!reset) begin
        for(i = 1; i < 32; i=i+1) begin
            regs[i] <= 32'h0;
        end
    end else if (wb_alu_to_reg && !IF_ID.stall_read && !(wb_stall || wb_nop_stall)) begin
        regs[wb_dest_reg_sel]    <= wb_mem_to_reg ? wb_read_data : wb_result;
    end
end

endmodule
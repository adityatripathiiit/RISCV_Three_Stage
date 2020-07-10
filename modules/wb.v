// stage 3: write back
////////////////////////////////////////////////////////////
module wb #(
            parameter  [31:0]    RESET   = 32'h0000_0000
            )
    (
    input clk,
    input reset
);

// import "opcode.vh" for OPCODES
`include "opcode.vh"


assign pipe.inst_mem_address           = pipe.fetch_pc;
assign pipe.inst_mem_is_ready           = !pipe.stall_read && !pipe.wb_stall;
assign pipe.wb_stall             = pipe.execute_stall || (pipe.wb_mem_to_reg && !pipe.dmem_write_valid);
assign pipe.wb_nop_stall             = pipe.wb_nop || pipe.wb_nop_more;




always @(posedge clk or negedge reset) begin
    if (!reset) begin
        pipe.inst_fetch_pc <= RESET;
    end
    else if (!pipe.stall_read && !pipe.wb_stall) begin
        pipe.inst_fetch_pc               <= pipe.fetch_pc;
    end
end


always @(posedge clk or negedge reset) begin
    if (!reset) begin
        pipe.wb_nop              <= 1'b0;
        pipe.wb_nop_more         <= 1'b0;
    end else if (!pipe.stall_read && !(pipe.execute_stall || (pipe.wb_mem_to_reg && !pipe.dmem_write_valid))) begin
        pipe.wb_nop              <= pipe.wb_branch;
        pipe.wb_nop_more         <= pipe.wb_nop;
    end
end

always @* begin
    case(pipe.wb_alu_operation)
        LB  : begin
                    case(pipe.wb_read_address[1:0])
                        2'b00: pipe.wb_read_data[31: 0] = {{24{pipe.dmem_read_data[7]}}, pipe.dmem_read_data[7:0]};
                        2'b01: pipe.wb_read_data[31: 0] = {{24{pipe.dmem_read_data[15]}}, pipe.dmem_read_data[15:8]};
                        2'b10: pipe.wb_read_data[31: 0] = {{24{pipe.dmem_read_data[23]}}, pipe.dmem_read_data[23:16]};
                        2'b11: pipe.wb_read_data[31: 0] = {{24{pipe.dmem_read_data[31]}}, pipe.dmem_read_data[31:24]};
                    endcase
                 end
        LH  : pipe.wb_read_data = (pipe.wb_read_address[1]) ? {{16{pipe.dmem_read_data[31]}}, pipe.dmem_read_data[31:16]} : {{16{pipe.dmem_read_data[15]}}, pipe.dmem_read_data[15:0]};
        LW  : pipe.wb_read_data = pipe.dmem_read_data;
        LBU : begin
                    case(pipe.wb_read_address[1:0])
                        2'b00: pipe.wb_read_data[31: 0] = {24'h0, pipe.dmem_read_data[7:0]};
                        2'b01: pipe.wb_read_data[31: 0] = {24'h0, pipe.dmem_read_data[15:8]};
                        2'b10: pipe.wb_read_data[31: 0] = {24'h0, pipe.dmem_read_data[23:16]};
                        2'b11: pipe.wb_read_data[31: 0] = {24'h0, pipe.dmem_read_data[31:24]};
                    endcase
                 end
        LHU : pipe.wb_read_data = (pipe.wb_read_address[1]) ? {16'h0, pipe.dmem_read_data[31:16]} : {16'h0, pipe.dmem_read_data[15:0]};
        default: pipe.wb_read_data = 'hx;
    endcase
end

////////////////////////////////////////////////////////////
// Register file
////////////////////////////////////////////////////////////


assign pipe.reg_rdata1[31: 0] = (pipe.src1_select == 5'h0) ? 32'h0 :
                        (!pipe.wb_nop_stall && pipe.wb_alu_to_reg && (pipe.wb_dest_reg_sel == pipe.src1_select)) ? (pipe.wb_mem_to_reg ? pipe.wb_read_data : pipe.wb_result) :
                        pipe.regs[pipe.src1_select];
assign pipe.reg_rdata2[31: 0] = (pipe.src2_select == 5'h0) ? 32'h0 :
                        (!pipe.wb_nop_stall && pipe.wb_alu_to_reg && (pipe.wb_dest_reg_sel == pipe.src2_select)) ? (pipe.wb_mem_to_reg ? pipe.wb_read_data : pipe.wb_result) :
                        pipe.regs[pipe.src2_select];

integer i;
always @(posedge clk or negedge reset) begin
    if (!reset) begin
        for(i = 1; i < 32; i=i+1) begin
            pipe.regs[i] <= 32'h0;
        end
    end else if (pipe.wb_alu_to_reg && !pipe.stall_read && !(pipe.wb_stall || pipe.wb_nop_stall)) begin
        // $display("hello");
        pipe.regs[pipe.wb_dest_reg_sel]    <= pipe.wb_mem_to_reg ? pipe.wb_read_data : pipe.wb_result;
    end
end

endmodule
////////////////////////////////////////////////////////////
// stage 3: Write Back
////////////////////////////////////////////////////////////
module wb 
#(
    parameter  [31:0]    RESET   = 32'h0000_0000
)
(
    input clk,
    input reset
);

// import "opcode.vh" for OPCODES
`include "opcode.vh"

// assigning these variables to read from the instruction memory
assign pipe.inst_mem_address            = pipe.fetch_pc; 
assign pipe.inst_mem_is_ready           = !pipe.stall_read;

// wb_stall flag for defining the first and second stall in branch instruction
assign pipe.wb_stall             = pipe.wb_stall_first || pipe.wb_stall_second;

always @(posedge clk or negedge reset) 
begin
    if (!reset) 
    begin
        pipe.inst_fetch_pc               <= RESET; // reset to instruction fetch program counter
    end
    else if (!pipe.stall_read) 
    begin // if stall is not there in branch
        pipe.inst_fetch_pc               <= pipe.fetch_pc;  // fetch the next instruction
    end
end

// Branch stall variable declarations
always @(posedge clk or negedge reset) 
begin
    if (!reset) 
    begin
        pipe.wb_stall_first              <= 1'b0;
        pipe.wb_stall_second             <= 1'b0;
    end 
    else if (!pipe.stall_read && !((pipe.wb_mem_to_reg && !pipe.dmem_write_valid))) 
    begin
        pipe.wb_stall_first              <= pipe.wb_branch;
        pipe.wb_stall_second             <= pipe.wb_stall_first;
    end
end


//Preparing write data for store type instructions

always @(posedge clk or negedge reset) 
begin
    if (!reset) 
    begin
        pipe.wb_write_address         <= 32'h0;
        pipe.wb_write_byte            <= 4'h0;
        pipe.wb_write_data            <= 32'h0;
    end 
    else if (!pipe.stall_read && pipe.mem_write) 
    begin
        pipe.wb_write_address         <= pipe.write_address;
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



always @* 
begin
    // load instruction based on the OPCODES
    case(pipe.wb_alu_operation)
        LB  : begin     // Load byte 
                    case(pipe.wb_read_address[1:0]) // a flag to define which byte to read and load
                        2'b00: pipe.wb_read_data[31: 0] = {{24{pipe.dmem_read_data[7]}}, pipe.dmem_read_data[7:0]};
                        2'b01: pipe.wb_read_data[31: 0] = {{24{pipe.dmem_read_data[15]}}, pipe.dmem_read_data[15:8]};
                        2'b10: pipe.wb_read_data[31: 0] = {{24{pipe.dmem_read_data[23]}}, pipe.dmem_read_data[23:16]};
                        2'b11: pipe.wb_read_data[31: 0] = {{24{pipe.dmem_read_data[31]}}, pipe.dmem_read_data[31:24]};
                    endcase
                 end
        // load halfword
        LH  : pipe.wb_read_data = (pipe.wb_read_address[1]) ? {{16{pipe.dmem_read_data[31]}}, pipe.dmem_read_data[31:16]} : {{16{pipe.dmem_read_data[15]}}, pipe.dmem_read_data[15:0]};
        LW  : pipe.wb_read_data = pipe.dmem_read_data;      // load word
        LBU : begin     // load byte unsigned
                    case(pipe.wb_read_address[1:0]) // a flag to define which byte to read and load
                        2'b00: pipe.wb_read_data[31: 0] = {24'h0, pipe.dmem_read_data[7:0]};
                        2'b01: pipe.wb_read_data[31: 0] = {24'h0, pipe.dmem_read_data[15:8]};
                        2'b10: pipe.wb_read_data[31: 0] = {24'h0, pipe.dmem_read_data[23:16]};
                        2'b11: pipe.wb_read_data[31: 0] = {24'h0, pipe.dmem_read_data[31:24]};
                    endcase
                 end
        // load halfword ungigned
        LHU : pipe.wb_read_data = (pipe.wb_read_address[1]) ? {16'h0, pipe.dmem_read_data[31:16]} : {16'h0, pipe.dmem_read_data[15:0]};
        default: pipe.wb_read_data = 'hx;
    endcase
end


endmodule
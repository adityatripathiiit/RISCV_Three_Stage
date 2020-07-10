`include "IF_ID.v"
`include "execute.v"
`include "wb.v"
 module pipe 
#(
        parameter [31:0]             RESET = 32'h0000_0000
)
(
   input                   clk,
    input                   reset,
    input                   stall,
    output              exception,  

    // interface of instruction Memory
    input                   inst_mem_is_valid,
    input           [31: 0] inst_mem_read_data,
    
   

    input           [31: 0] dmem_read_data_temp,
    input                   dmem_write_valid,
    input                   dmem_read_valid
  
);
wire [31:0] dmem_read_data;
assign dmem_read_data = dmem_read_data_temp ;

wire                  dmem_write_ready;
wire                  dmem_read_ready;
wire          [31: 0] dmem_write_address;
wire          [31: 0] dmem_read_address;
wire          [31: 0] dmem_write_data;
wire          [ 3: 0] dmem_write_byte;
wire                 inst_mem_is_ready;


reg           [31: 0] immediate;
reg                   immediate_sel;
reg           [ 4: 0] src1_select;
reg            [ 4: 0] src2_select;
reg            [ 4: 0] dest_reg_sel;
reg            [ 2: 0] alu_operation;
reg                    arithsubtype;
reg                   mem_write;
reg                    mem_to_reg;
reg                    illegal_inst;
reg            [31: 0] execute_immediate;
reg                   alu;
reg                    lui;
reg                    jal;
reg                    jalr;
reg                    branch;
reg                    stall_read;
wire             [31:0] instruction;
// pc wires

reg            [31: 0] pc;
reg           [31: 0] inst_fetch_pc;

//stalls
wire                    inst_fetch_stall;
reg                    flush;


reg           [31:0]  fetch_pc ;               
wire            [31:0]  reg_rdata2 ;         


wire            [32: 0] result_subs;        //Substraction Signed
wire            [32: 0] result_subu;        //Substraction Unsigned
reg           [31: 0] result;
reg            [31: 0] next_pc;
wire            [31: 0] write_address;

reg                   branch_taken;
wire                     branch_stall;

// write back 
reg                    wb_alu_to_reg;
reg           [31: 0] wb_result;
reg            [ 2: 0] wb_alu_operation;
reg                   wb_mem_write;
reg                   wb_mem_to_reg;
reg           [ 4: 0] wb_dest_reg_sel;
reg                  wb_branch;
reg                    wb_branch_nxt;
reg            [31: 0] wb_write_address;
reg           [ 1: 0] wb_read_address;
reg           [ 3: 0] wb_write_byte;
reg            [31: 0] wb_write_data;

reg[31: 0] wb_read_data;
reg wb_nop;
reg wb_nop_more;
wire [31: 0] reg_rdata1;
reg[31: 0] regs [31: 1];

wire    wb_stall;
wire    wb_nop_stall;

wire          [31: 0] inst_mem_address;


// Selecting the first and second operands of ALU unit
wire[31:0] alu_operand1;
wire[31:0] alu_operand2;

wire                    execute_stall;

wire dmem_read_valid_checker = 1'b1; 

IF_ID IF_ID(
    .clk        (clk),
    .reset     (reset),
    .stall      (stall),
    .exception  (exception),
    .inst_mem_read_data (inst_mem_read_data),
    .inst_mem_is_valid (inst_mem_is_valid)
);

execute execute(
    .clk        (clk),
    .reset     (reset)
   
   );

wb wb(
    .clk        (clk),
    .reset     (reset)
   );


                     
endmodule                     
             
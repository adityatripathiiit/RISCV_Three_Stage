// `include "opcode.vh"
module testbench();
    localparam      IMEMSIZE = 128*1024;
    localparam      DMEMSIZE = 128*1024;

    // pc counter and checker
    reg     [31: 0] next_pc;
    reg     [ 7: 0] count;

    reg             clk;
    reg             reset;
    reg             stall;
    wire            exception;
    wire            inst_mem_is_ready;
    wire    [31: 0] inst_mem_read_data;
    wire            inst_mem_is_valid;
    wire    [31: 0] inst_mem_address;

    wire            dmem_read_ready;
    wire            dmem_write_ready;
    wire    [31: 0] dmem_read_data;
    wire            dmem_read_valid;
    wire            dmem_write_valid;
    wire    [31: 0] dmem_read_address;
    wire    [31: 0] dmem_write_address;
    wire    [31: 0] dmem_write_data;
    wire    [ 3: 0] dmem_write_byte;

assign dmem_read_valid  = 1'b1;
assign dmem_write_valid  = 1'b1;

assign inst_mem_is_valid   = 1'b1;

initial
begin
     $monitor("result=%h",IF_ID.instruction);
end


initial 
begin

    clk            <= 1'b1;
    reset          <= 1'b0;

    repeat (10) @(posedge clk);
    reset          <= 1'b1;

    repeat (10) @(posedge clk);
    stall           <= 1'b0;

end

always #10 clk      <= ~clk;


// check timeout if the PC do not change anymore
always @(posedge clk or negedge reset) begin
    if (!reset) begin
        next_pc     <= 32'h0;
        count       <= 8'h0;
    end else begin
        next_pc     <= IF_ID.inst_fetch_pc;

        if (next_pc == IF_ID.inst_fetch_pc)
            count   <= count + 1;
        else
            count   <= 8'h0;

        if (count > 100) begin
            $display("Executing timeout");
            #10 $finish(2);
        end
    end
end

// stop at exception
always @(posedge clk) begin
    if (exception) begin
        $display("All instructions are Fetched");
        #10 $finish(2);
    end
end

// Instantiating the modules

///////////////////////////////////////////////////////////
/////// Instanatiate Instruction memory
//////////////////////////////////////////////////////////


    memory # (
        .SIZE(IMEMSIZE),
        .FILE("../mem_generator/imem_dmem/imem.hex")
        
    ) inst_mem (
        .clk   (clk),
        .read_ready(1'b1),
        .write_ready(1'b0),
        .read_data (inst_mem_read_data),
        .read_address (IF_ID.inst_fetch_pc[31:2]),
        .write_address (30'h0),
        .write_data (32'h0),
        .write_byte (4'h0)
    );

///////////////////////////////////////////////////////////
/////// Instanatiate Data memory
//////////////////////////////////////////////////////////
    memory # (
        .SIZE(DMEMSIZE),
        .FILE("../mem_generator/imem_dmem/dmem.hex")
    ) dmem (
        .clk   (clk),

        .read_ready(dmem_read_ready),
        .write_ready(dmem_write_ready),
        .read_data (dmem_read_data),
        .read_address (dmem_read_address[31:2]),
        .write_address (dmem_write_address[31:2]),
        .write_data (dmem_write_data),
        .write_byte (dmem_write_byte)
    );


///////////////////////////////////////////////////////////
/////// Instanatiate IF/ID stage
//////////////////////////////////////////////////////////

IF_ID IF_ID(
    .clk        (clk),
    .reset     (reset),
    .stall      (stall),
    .exception  (exception),
    .inst_mem_is_ready (inst_mem_is_ready),
    .inst_mem_read_data (inst_mem_read_data),
    .inst_mem_is_valid (inst_mem_is_valid),
    .inst_mem_address  (inst_mem_address)
);

///////////////////////////////////////////////////////////
/////// Instanatiate Execute stage
//////////////////////////////////////////////////////////
execute execute(
    .clk        (clk),
    .reset     (reset),
    .immediate_sel(IF_ID.immediate_sel),
    .immediate(IF_ID.immediate),
    .mem_write(IF_ID.mem_write),
    .mem_to_reg(IF_ID.mem_to_reg),
    .jal(IF_ID.jal),
    .jalr(IF_ID.jalr),
    .lui(IF_ID.lui),
    .alu(IF_ID.alu),
    .alu_operation(IF_ID.alu_operation),
    .arithsubtype(IF_ID.arithsubtype),
    .pc(IF_ID.pc),
    .dest_reg_sel(IF_ID.dest_reg_sel),
    .dmem_read_valid(dmem_read_valid)
   );

///////////////////////////////////////////////////////////
/////// Instanatiate Write Back stage
//////////////////////////////////////////////////////////
wb wb(
    .clk        (clk),
    .reset     (reset),
    .wb_read_address(execute.wb_read_address),
    .wb_branch(execute.wb_branch),
    .src1_select(IF_ID.src1_select),
    .src2_select(IF_ID.src2_select),
    .wb_alu_to_reg(execute.wb_alu_to_reg),
    .wb_dest_reg_sel(execute.wb_dest_reg_sel),
    .wb_result(execute.wb_result),
    .wb_mem_to_reg(execute.wb_mem_to_reg),
    .wb_alu_operation(execute.wb_alu_operation),
    .dmem_write_ready(dmem_write_ready),
    .dmem_read_ready(dmem_read_ready),
    .dmem_read_data(dmem_read_data),
    .dmem_write_valid(dmem_write_valid),
    .dmem_read_valid(dmem_read_valid),
    .dmem_write_address(dmem_write_address),
    .dmem_read_address(dmem_read_address),
    .dmem_write_data(dmem_write_data),
    .dmem_write_byte(dmem_write_byte)
   );


// check memory range
always @(posedge clk) begin
    if (inst_mem_is_ready && inst_mem_address[31:$clog2(IMEMSIZE)] != 'd0) begin
        $display("IMEM address %x out of range", inst_mem_address);
        #10 $finish(2);
    end
    if (dmem_write_ready && dmem_write_address[31:$clog2(DMEMSIZE+IMEMSIZE)] != 'd0) begin
        $display("DMEM address %x out of range", dmem_write_address);
        #10 $finish(2);
    end
end

endmodule

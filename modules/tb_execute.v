// `include "opcode.vh"

`define MEM_PUTC    32'h8000001c
`define MEM_EXIT    32'h8000002c

module testbench();
    //localparam      DRAMSIZE = 128*1024;
    localparam      IRAMSIZE = 128*1024;

    reg             clk;
    reg             resetb;
    wire            exception;
    // Instruction memory wires
    wire            imem_ready;
    wire  reg  [31: 0] imem_rdata;
    wire            imem_valid;
    wire    [31: 0] imem_addr;
   

    // pc counter and checker
    reg     [31: 0] next_pc;
    reg     [ 7: 0] count;

assign imem_valid   = 1'b1;

initial
begin
     $monitor("result=%d",execute.ex_imm);
end

initial begin

    if ($test$plusargs("dumpvcd")) begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
    end

    clk             <= 1'b1;
    resetb          <= 1'b0;

    //repeat (10) @(posedge clk);
    # 10 resetb          <= 1'b1;

end

always #10 clk      <= ~clk;


// check timeout if the PC do not change anymore
always @(posedge clk or negedge resetb) begin
    if (!resetb) begin
        next_pc     <= 32'h0;
        count       <= 8'h0;
    end else begin
        next_pc     <= IF_ID.if_pc;

        if (next_pc == IF_ID.if_pc)
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
        $display("Exception occurs, simulation exist.");
        #10 $finish(2);
    end
end


// Instantiating the modules and

///////////////////////////////////////////////////////////
/////// Instanatiate Instruction memory
//////////////////////////////////////////////////////////

    memmodel # (
        .SIZE(IRAMSIZE),
        .FILE("../mem_generator/imem_dmem/imem.hex")
    ) imem (
        .clk   (clk),

        .rready(1'b1),
        .wready(1'b0),
        .rdata (imem_rdata),
        .raddr (IF_ID.if_pc[31:2]),
        .waddr (30'h0),
        .wdata (32'h0),
        .wstrb (4'h0)
    );

///////////////////////////////////////////////////////////
/////// Instanatiate IF/ID stage
//////////////////////////////////////////////////////////

IF_ID IF_ID(
    .clk        (clk),
    .resetb     (resetb),
    .exception  (exception),

    .imem_ready (imem_ready),
    .imem_rdata (imem_rdata),
    .imem_valid (imem_valid),
    .imem_addr  (imem_addr)
);

///////////////////////////////////////////////////////////
/////// Instanatiate Execute stage
//////////////////////////////////////////////////////////
execute execute(
    .clk        (clk),
    .resetb     (resetb),
    //.dmem_rdata(dmem_rdata),
    .ex_imm_sel(IF_ID.ex_imm_sel),
    .ex_imm(IF_ID.ex_imm),
    .ex_memwr(IF_ID.ex_memwr),
    .ex_mem2reg(IF_ID.ex_mem2reg),
    .ex_jal(IF_ID.ex_jal),
    .ex_jalr(IF_ID.ex_jalr),
    .ex_lui(IF_ID.ex_lui),
    .ex_auipc(IF_ID.ex_auipc),
    .ex_csr(IF_ID.ex_csr),
    .ex_alu(IF_ID.ex_alu),
    .ex_alu_op(IF_ID.ex_alu_op),
    .ex_subtype(IF_ID.ex_subtype),
    .ex_pc(IF_ID.ex_pc),
    .ex_dst_sel(IF_ID.ex_dst_sel)
   );




// check memory range
always @(posedge clk) begin
    if (imem_ready && imem_addr[31:$clog2(IRAMSIZE)] != 'd0) begin
        $display("IMEM address %x out of range", imem_addr);
        #10 $finish(2);
    end

end

endmodule

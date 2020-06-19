// `include "opcode.vh"

`define MEM_PUTC    32'h8000001c
`define MEM_EXIT    32'h8000002c

module testbench();
    localparam      DRAMSIZE = 128*1024;
    localparam      IRAMSIZE = 128*1024;

    reg             clk;
    reg             resetb;
    wire            exception;
    // Instruction memory wires
    wire            imem_ready;
    wire reg   [31: 0] imem_rdata;
    wire            imem_valid;
    wire    [31: 0] imem_addr;
    // Data memory wires 
    wire            dmem_rready;
    wire            dmem_wready;
    wire    [31: 0] dmem_rdata;
    wire            dmem_rvalid;
    wire            dmem_wvalid;
    wire    [31: 0] dmem_raddr;
    wire    [31: 0] dmem_waddr;
    wire    [31: 0] dmem_wdata;
    wire    [ 3: 0] dmem_wstrb;


    // execute stage wires
    wire    [31:0]    wb_result,
    wire              wb_memwr,
    wire              wb_alu2reg,
    wire    [4:0]     wb_dst_sel,
    wire              wb_mem2reg,
    wire    [1:0]     wb_raddr,
    wire    [2:0]     wb_aluop,
    //wire          wb_branch,
    //wire          wb_branch_nxt,
    wire    [31:0]    wb_waddr,
    wire    [3:0]     wb_wstrb,
    wire    [31:0]    wb_wdata


    // pc counter and checker
    reg     [31: 0] next_pc;
    reg     [ 7: 0] count;

assign dmem_rvalid  = 1'b1;
assign dmem_wvalid  = 1'b1;
assign imem_valid   = 1'b1;

initial
      $monitor("inst=%h",imem_rdata);
      $monitor("result=%d",wb_result);


initial begin

    if ($test$plusargs("dumpvcd")) begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
    end

    clk             <= 1'b1;
    resetb          <= 1'b0;

    repeat (10) @(posedge clk);
    resetb          <= 1'b1;

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
    .wb_result(wb_result),
    .wb_memwr(wb_memwr),
    .wb_alu2reg(wb_alu2reg),
    .wb_dst_sel(wb_dst_sel),
    .wb_mem2reg(wb_mem2reg),
    .wb_raddr(wb_raddr),
    .wb_aluop(wb_aluop),
    .wb_branch(wb_branch),
    .wb_branch_nxt(wb_branch_nxt),
    .wb_waddr(wb_waddr),
    .wb_wstrb(wb_wstrb),
    .wb_wdat(wb_wdat)
);


///////////////////////////////////////////////////////////
/////// Instanatiate Instruction memory
//////////////////////////////////////////////////////////

    memmodel # (
        .SIZE(IRAMSIZE),
        .FILE("../memory_data/imem.hex")
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
/////// Instanatiate Data memory
//////////////////////////////////////////////////////////
     memmodel # (
        .SIZE(DRAMSIZE),
        .FILE("../memory_data/dmem.hex")
    ) dmem (
        .clk   (clk),
        .rready(execute.dmem_rready),
        .wready(execute.dmem_wready),
        .rdata (execute.dmem_rdata),
        .raddr (execute.dmem_raddr[31:2]),
        .waddr (execute.dmem_waddr[31:2]),
        .wdata (execute.dmem_wdata),
        .wstrb (execute.dmem_wstrb)
    );




// check memory range
always @(posedge clk) begin
    if (imem_ready && imem_addr[31:$clog2(IRAMSIZE)] != 'd0) begin
        $display("IMEM address %x out of range", imem_addr);
        #10 $finish(2);
    end

    if (execute.dmem_wready && execute.dmem_waddr == `MEM_PUTC) begin
        $write("%c", execute.dmem_wdata[7:0]);
    end
    else if (execute.dmem_wready && execute.dmem_waddr == `MEM_EXIT) begin
        // $display("\nExcuting %0d instructions, %0d cycles", riscv.rdinstret, riscv.rdcycle);
        $display("\nExcuting %0d instructions, %0d cycles", 1'b1, 1'b1);

        $display("Program terminate");
        #10 $finish(1);
    end
    else if (execute.dmem_wready && execute.dmem_waddr[31:$clog2(DRAMSIZE+IRAMSIZE)] != 'd0) begin
        $display("DMEM address %x out of range", execute.dmem_waddr);
        #10 $finish(2);
    end
end


`ifdef TRACE
    integer         fp;

    reg [7*8:1] regname;

initial begin
    if ($test$plusargs("trace")) begin
        fp = $fopen("trace.log", "w");
    end
end

always @* begin
    case(wb_dst_sel)
        'd0: regname = "zero";
        'd1: regname = "ra";
        'd2: regname = "sp";
        'd3: regname = "gp";
        'd4: regname = "tp";
        'd5: regname = "t0";
        'd6: regname = "t1";
        'd7: regname = "t2";
        'd8: regname = "s0(fp)";
        'd9: regname = "s1";
        'd10: regname = "a0";
        'd11: regname = "a1";
        'd12: regname = "a2";
        'd13: regname = "a3";
        'd14: regname = "a4";
        'd15: regname = "a5";
        'd16: regname = "a6";
        'd17: regname = "a7";
        'd18: regname = "s2";
        'd19: regname = "s3";
        'd20: regname = "s4";
        'd21: regname = "s5";
        'd22: regname = "s6";
        'd23: regname = "s7";
        'd24: regname = "s8";
        'd25: regname = "s9";
        'd26: regname = "s10";
        'd27: regname = "s11";
        'd28: regname = "t3";
        'd29: regname = "t4";
        'd30: regname = "t5";
        'd31: regname = "t6";
        default: regname = "xx";
    endcase
end




endmodule

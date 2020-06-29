`timescale 1ns/100fs 
module testbench();
    localparam      IMEMSIZE = 128*1024;

    // pc counter and checker
    reg     [31: 0] next_pc;
    reg     [ 7: 0] count;


    reg             clk;
    reg             reset;
    wire            exception;
    wire            inst_mem_is_ready;
    wire    [31: 0] inst_mem_read_data;
    wire            inst_mem_is_valid;
    wire    [31: 0] inst_mem_addr;


initial
      $monitor("time= %t , alu_operation=%h",$time, IF_ID.alu_operation);


initial 
begin

    clk            <= 1'b1;
    reset          <= 1'b0;

    repeat (10) @(posedge clk);
    reset          <= 1'b1;

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

IF_ID IF_ID(
    .clk        (clk),
    .reset     (reset),
    .exception  (exception),
    .inst_mem_is_ready (inst_mem_is_ready),
    .inst_mem_read_data (inst_mem_read_data),
    .inst_mem_is_valid (inst_mem_is_valid),
    .inst_mem_addr  (inst_mem_addr)
);


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



// check memory range
always @(posedge clk) begin
    if (inst_mem_is_ready && inst_mem_addr[31:$clog2(IMEMSIZE)] != 'd0) begin
        $display("IMEM address %x out of range", inst_mem_addr);
        #10 $finish(2);
    end
end

endmodule




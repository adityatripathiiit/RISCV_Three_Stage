module testbench();
    
    //Local Parameters
    localparam      IMEMSIZE = 4096;
    localparam      DMEMSIZE = 4096;

    // PC counter and checker
    reg     [31: 0] next_pc;
    reg     [ 7: 0] count;

    reg             clk;
    reg             reset;
    reg             stall;
    wire            exception;
    wire    [31: 0] inst_mem_read_data;
    wire            inst_mem_is_valid;
    wire            dmem_write_valid;
    wire            dmem_read_valid;
    wire    [31: 0] dmem_read_data_temp;
    

assign dmem_write_valid    = 1'b1;
assign dmem_read_valid     = 1'b1; 
assign inst_mem_is_valid   = 1'b1;


initial
begin
     $monitor("time: %t ,result =%d",$time,pipe.regs[15]);
end

initial
begin
    $dumpfile("pipeline.vcd");
    $dumpvars(0,pipe);
end


initial 
begin

    clk            <= 1'b1;
    reset          <= 1'b0;
    stall          <= 1'b1;

    repeat (10) @(posedge clk);
    reset          <= 1'b1;

    repeat (10) @(posedge clk);
    stall           <= 1'b0;

end

always #10 clk      <= ~clk;


// check timeout if the PC do not change anymore
always @(posedge clk or negedge reset) 
begin
    if (!reset) 
    begin
        next_pc     <= 32'h0;
        count       <= 8'h0;
        pipe.regs[2] <= 32'h00000fff;
    end 
    else 
    begin
        next_pc     <= pipe.inst_fetch_pc;

        if (next_pc == pipe.inst_fetch_pc)
            count   <= count + 1;
        else
            count   <= 8'h0;
        if (count > 100) 
        begin
            $display("Executing timeout");
            #10 $finish(2);
        end
    end
end

// stop at exception
always @(posedge clk) 
begin
    if (exception) 
    begin
        $display("All instructions are Fetched");
        #10 $finish(2);
    end
end

///////////////////////////////////////////////////////////
/////// Instanatiate Data memory
///////////////////////////////////////////////////////////
    memory # (
        .SIZE(DMEMSIZE),
        .FILE("../mem_generator/imem_dmem/dmem.hex")
    ) dmem (
        .clk   (clk),
        .read_ready(pipe.dmem_read_ready),
        .write_ready(pipe.dmem_write_ready),
        .read_data (dmem_read_data_temp),
        .read_address (pipe.dmem_read_address[31:2]),
        .write_address (pipe.dmem_write_address[31:2]),
        .write_data (pipe.dmem_write_data),
        .write_byte (pipe.dmem_write_byte)
    );

///////////////////////////////////////////////////////////
/////// Instanatiate Instruction memory
///////////////////////////////////////////////////////////

    memory # (
        .SIZE(IMEMSIZE),
        .FILE("../mem_generator/imem_dmem/imem.hex")
        
    ) inst_mem (
        .clk   (clk),
        .read_ready(1'b1),
        .write_ready(1'b0),
        .read_data (inst_mem_read_data),
        .read_address (pipe.inst_mem_address[31:2]),
        .write_address (30'h0),
        .write_data (32'h0),
        .write_byte (4'h0)
    );

///////////////////////////////////////////////////////////
/////// Instanatiate Pipeline Module
//////////////////////////////////////////////////////////

pipe pipe(
    .clk        (clk),
    .reset     (reset),
    .stall      (stall),
    .exception  (exception),
    .inst_mem_read_data (inst_mem_read_data),
    .inst_mem_is_valid (inst_mem_is_valid),
    .dmem_read_data_temp(dmem_read_data_temp),
    .dmem_write_valid(dmem_write_valid),
    .dmem_read_valid(dmem_read_valid)
);

//check memory range
always @(posedge clk) 
begin
    if (pipe.inst_mem_is_ready && pipe.inst_mem_address[31:$clog2(IMEMSIZE)] != 'd0) 
    begin
        $display("IMEM address %x out of range", pipe.inst_mem_address);
        #10 $finish(2);
    end
    if (pipe.dmem_write_ready  && pipe.dmem_write_address[31:$clog2(DMEMSIZE)] != 'd0) 
    begin
        $display("DMEM address %x out of range", pipe.dmem_write_address);
        #10 $finish(2);
    end
end

endmodule


module memory # (
    // Loading the hex file generated from the cross-compiler
    parameter FILE  = "../memory_data/imem.hex",
    //  Defining the maximum size of the memory files
    parameter SIZE  = 4096
    
) (
    input               clk,
    input               read_ready,
    input               write_ready,
    input       [31: 2] write_address,
    input       [31: 0] write_data,
    input       [ 3: 0] write_byte,
    output reg  [31: 0] read_data,
    input       [31: 2] read_address
    
);

    localparam ADDR = $clog2(SIZE/4);
    wire        [ADDR-1: 0] read_addr;
    wire        [ADDR-1: 0] write_addr;
    reg         [31: 0] memory [(SIZE/4)-1: 0];
    integer                 i;

assign read_addr[ADDR-1: 0] = read_address[ADDR+1: 2];
assign write_addr[ADDR-1: 0] = write_address[ADDR+1: 2];

initial begin
// initializing memory and loading data in the hex file in the reg memory
    if ($test$plusargs("meminit")) begin
        for (i=0; i<SIZE/4; i=i+1) memory[i] = 32'h0;
    end
// Reading and storing data in bytes, the stan read_data <= memory[read_addr];
    $readmemh(FILE, memory, 0, SIZE/4-1);
end

always @(posedge clk) begin
    if (write_ready) begin
        if (write_byte[0]) memory[write_addr][8*0+7:8*0] <= write_data[8*0+7:8*0];
        if (write_byte[1]) memory[write_addr][8*1+7:8*1] <= write_data[8*1+7:8*1];
        if (write_byte[2]) memory[write_addr][8*2+7:8*2] <= write_data[8*2+7:8*2];
        if (write_byte[3]) memory[write_addr][8*3+7:8*3] <= write_data[8*3+7:8*3];
    end

    if (read_ready) begin
        if (write_ready && read_addr == write_addr) begin
            read_data[8*0+7:8*0] <= (write_byte[0]) ? write_data[8*0+7:8*0] : memory[read_addr][8*0+7:8*0];
            read_data[8*1+7:8*1] <= (write_byte[1]) ? write_data[8*1+7:8*1] : memory[read_addr][8*1+7:8*1];
            read_data[8*2+7:8*2] <= (write_byte[2]) ? write_data[8*2+7:8*2] : memory[read_addr][8*2+7:8*2];
            read_data[8*3+7:8*3] <= (write_byte[3]) ? write_data[8*3+7:8*3] : memory[read_addr][8*3+7:8*3];
        end else begin
            read_data <= memory[read_addr];
        end
    end
end

endmodule
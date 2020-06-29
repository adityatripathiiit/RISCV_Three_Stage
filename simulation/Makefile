# Build flags
BFLAGS = -f filelist.txt


TARGET = riscv_output

all: $(TARGET)

$(TARGET): $(SRC)
	iverilog $(BFLAGS) -o $(TARGET)
	vvp riscv_output
	make clean
run: $(TARGET)
	./$(TARGET)

clean:
	@$(RM) $(TARGET) 

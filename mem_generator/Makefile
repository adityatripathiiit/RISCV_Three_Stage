#//////////////////////////////////////////////////////
#/////////////////INCLUDING CROSS-COMPILER/////////////

CC      = riscv32-unknown-elf-gcc
AR      = riscv32-unknown-elf-ar
OBJDUMP = riscv32-unknown-elf-objdump
OBJCOPY = riscv32-unknown-elf-objcopy
READELF = riscv32-unknown-elf-readelf


#///// flags for RV32i architecture///////////////////
CFLAGS  = -march=rv32i -mabi=ilp32
# LDFLAGS = -lc -lm -lgcc

#////Source for c code file ///////////////////////////
SRC      = code.c

#///// Default value flags for RV32i architecture//////
# LDFLAGS += -T ./default.ld
#///// Target name for generated files ////////////////
TARGET   = code.elf

.PHONY: all clean

#/// generating .text file of code cross-compiled from highlevel-c code to risc-v code
# ////////////// Copying and converting the text file into binary files
#/////// Python script to convert the binary files into the required hex files

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) -c  $(SRC) -o $(TARGET) $(CFLAGS)
	$(OBJCOPY) -O binary $(TARGET) ./imem_dmem/imem.bin
	$(OBJCOPY) -j .data -O binary $(TARGET) ./imem_dmem/dmem.bin
	$(OBJDUMP) -d $(TARGET) > ./imem_dmem/code.dis
	cd imem_dmem && python3 bin2hex.py
# /////clean function
clean:
	$(RM) $(TARGET) ./imem_dmem/imem.bin ./imem_dmem/imem.hex ./imem_dmem/dmem.bin ./imem_dmem/dmem.hex ./imem_dmem/code.dis

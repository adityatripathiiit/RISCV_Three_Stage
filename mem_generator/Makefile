#//////////////////////////////////////////////////////
#/////////////////INCLUDING CROSS-COMPILER/////////////

CC      = riscv-none-embed-gcc
OBJCOPY = riscv-none-embed-objcopy

#///// flags for RV32i architecture///////////////////
CFLAGS  = -O3 -Wall -march=rv32i -nostartfiles -nostdlib
LDFLAGS = -lc -lm -lgcc

#////Source for c code file ///////////////////////////
SRC      = code.c

#///// Default value flags for RV32i architecture//////
LDFLAGS += -T ./default.ld
#///// Target name for generated files ////////////////
TARGET   = code

.PHONY: all clean

#/// generating .text file of code cross-compiled from highlevel-c code to risc-v code
# ////////////// Copying and converting the text file into binary files
#/////// Python script to convert the binary files into the required hex files

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)
	$(OBJCOPY) -j .text -O binary $(TARGET) ./imem_dmem/imem.bin
	$(OBJCOPY) -j .data -O binary $(TARGET) ./imem_dmem/dmem.bin
	cd imem_dmem && python bin2hex.py
# /////clean function
clean:
	$(RM) $(TARGET) ./imem_dmem/imem.bin ./imem_dmem/imem.hex ./imem_dmem/dmem.bin ./imem_dmem/dmem.hex

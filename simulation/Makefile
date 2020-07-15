# Build flags
BFLAGS = -f filelist.txt


TARGET = riscv_output

help:
	@echo make sort        build all hex files and run the simulation for sorting program
	@echo make addition    build all hex files and run the simulation for addition program
	@echo make fibonacci   build all hex files and run the simulation for fibonacci program
	@echo make shifting    build all hex files and run the simulation for shifting program
	@echo make negative    build all hex files and run the simulation for negative program
	@echo make xor         build all hex files and run the simulation for xor immediate program  

sort: 
	cd ../mem_generator && $(MAKE) clean
	$(MAKE) sort -C ../mem_generator
	iverilog $(BFLAGS) -o riscv_output
	vvp riscv_output
	make clean


addition: 
	cd ../mem_generator && $(MAKE) clean
	$(MAKE) addition -C ../mem_generator
	iverilog $(BFLAGS) -o riscv_output
	vvp riscv_output
	make clean

fibonacci: 
	cd ../mem_generator && $(MAKE) clean
	$(MAKE) fibonacci -C ../mem_generator
	iverilog $(BFLAGS) -o riscv_output
	vvp riscv_output
	make clean


shifting: 
	cd ../mem_generator && $(MAKE) clean
	$(MAKE) shifting -C ../mem_generator
	iverilog $(BFLAGS) -o riscv_output
	vvp riscv_output
	make clean

negative: 
	cd ../mem_generator && $(MAKE) clean
	$(MAKE) negative -C ../mem_generator
	iverilog $(BFLAGS) -o riscv_output
	vvp riscv_output
	make clean

xor: 
	cd ../mem_generator && $(MAKE) clean
	$(MAKE) xor -C ../mem_generator
	iverilog $(BFLAGS) -o riscv_output
	vvp riscv_output
	make clean

clean:
	@$(RM) $(TARGET) 

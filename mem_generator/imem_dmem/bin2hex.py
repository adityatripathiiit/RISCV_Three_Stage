import struct
MEMINIT = 1
RAMSIZE = 4096

def hexChange(string):
    string = string[2:]
    zeros = 8-len(string)
    new_str = "0"*zeros + string
    return new_str

def bin2hex(in_file, out_file):
	inputFile = open(in_file, 'rb')
	outputFile = open(out_file, 'w')
	j = 0
	chunk = 4
	while True:
		data = inputFile.read(chunk)
		if not data:
			break
		data = struct.unpack("I",data)
		outputFile.write(hexChange(str(hex(data[0]))) + " // 32'h" + hexChange(str(hex(j)))+ "\n")
		j+=4
	
	while(j<RAMSIZE):
		if (MEMINIT):
			outputFile.write("00000000 // 32'h"+hexChange(str(hex(j)))+ "\n")
		else:
			outputFile.write("xxxxxxxx // 32'h"+hexChange(str(hex(j))) + "\n")
		j+=4
	inputFile.close()
	outputFile.close()

bin2hex("imem.bin", "imem.hex")
bin2hex("dmem.bin", "dmem.hex")

nanobug.s19:nanobug.asm iolib.asm
	lwasm -9 -f srec -o nanobug.s19 -lnanobug.lst --symbol-dump=nanobug.sym -mnanobug.map nanobug.asm

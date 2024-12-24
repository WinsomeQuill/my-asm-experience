BIN_DIR = bin/bin

password_generator:
	nasm -f elf nasm_password_generator/main.asm
	ld -m elf_i386 -s -o nasm_password_generator/$(BIN_DIR) nasm_password_generator/main.o
	./nasm_password_generator/$(BIN_DIR)

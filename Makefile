all:
	nasm -g -f elf64 tareaImagen.asm  -o tareaImagen.o
	nasm -g -f elf64 filters.asm  -o filters.o
	ld tareaImagen.o filters.o -o ejecutable

.PHONY:

clean:
	rm -f *.o ejecutable copia.bmp

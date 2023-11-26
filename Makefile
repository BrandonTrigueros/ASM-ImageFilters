all:
	nasm -g -f elf64 tareaImagen.asm  -o tareaImagen.o
	ld tareaImagen.o -o ejecutable

.PHONY:

clean:
	rm -f *.o ejecutable copia.bmp

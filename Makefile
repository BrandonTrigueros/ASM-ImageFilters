all:
	nasm -g -f elf64 tareaImagen.asm -o tareaImagen.o
	nasm -g -f elf64 filters.asm -o filters.o
	g++ -g -no-pie main.cpp tareaImagen.o filters.o -lSDL2 -o ejecutable
.PHONY:

clean:
	rm -f *.o ejecutable copia.bmp copia0.bmp copia1.bmp copia2.bmp copia3.bmp

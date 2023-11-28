; UNIVERSIDAD DE COSTA RICA
; CURSO: Lenguaje Ensamblador
; TAREA PROGRAMADA 2

; DESCRIPCIÓN:
;   Programa en lenguaje ensamblador que aplica un filtro a una imagen BMP
;   y crea una copia de la imagen con el filtro aplicado.

; INTEGRANTES
;   Brandon Trigeuros Lara C17899
; 	Henry Rojas Fuentes C16812


section .data

; --------------------- CONSTANTES ---------------------
	NULL equ 0 ; caracter de final de string
	SYS_read equ 0 ; lectura
	SYS_write equ 1 ; escritura
	SYS_open equ 2 ; abrir archivo
	SYS_close equ 3 ; cerrar archivo
	SYS_creat equ 85 ; abrir/crear archivo
	O_RDONLY equ 000000q ; solo lectura
	S_IRUSR equ 00400q ; permisos de lectura
	S_IWUSR equ 00200q ; permisos de escritura

; --------------------- VARIABLES ---------------------

	copyPath db "copia.bmp", NULL
	posterizationLevels dq 4	; rango de 2 a 256
	filter db 3	; 0 para negativo, 1 para posterize, 2 para grayscale, 3 para black and white

; -----------------------------------------------------
section .bss

	fileDescriptor resq 1
	copyFileDescriptor resq 1
	pixelDataOffset resb 4
	width resb 4
	height resb 4
	bitCount resb 2
	byteCount resb 2
	ingoredBytes resb 170
	pixelMatrix resb 10000000

;------------------------------------------------------
section .text
	extern negFilter, posterizeFilter, grayScaleFilter, blackAndWhiteFilter

; Función principal: crea una copia de la imagen BMP con el filtro aplicado
global crearCopia
crearCopia:
	mov [filter], sil ; Obtiene la opción del filtro
	mov rsi, rdi
	; Se abre el archivo
	call openBMP

	; Se crea el archivo de copia
	mov rdi, copyPath
	call createBMP

	; Se ignora 10 bytes
	mov edi, 10 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	call ignoreBytes

	; Se copian los bytes ignorados al archivo de copia
	mov rdi, ingoredBytes
	mov edx, 10 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	call writeToCopy

	; Se lee el offset de los datos de los pixeles
	mov rdi, qword[fileDescriptor]
	mov rax, SYS_read
	mov rsi, pixelDataOffset
	mov edx, 4 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	syscall

	; Se copia el offset al archivo de copia
	mov rdi, pixelDataOffset
	mov edx, 4 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	call writeToCopy

	; Se ignora 4 bytes
	mov edi, 4 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	call ignoreBytes

	; Se copian los bytes ignorados al archivo de copia
	mov rdi, ingoredBytes
	mov edx, 4 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	call writeToCopy

	; Se lee el ancho de la imagen
	mov rdi, qword[fileDescriptor]
	mov rax, SYS_read
	mov rsi, width
	mov edx, 4 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	syscall

	; Se copia el ancho de la imagen al archivo de copia
	mov rdi, width
	mov edx, 4 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	call writeToCopy

	; Se lee el alto de la imagenss
	mov rdi, qword[fileDescriptor]
	mov rax, SYS_read
	mov rsi, height
	mov edx, 4 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	syscall

	; Se copia el alto de la imagen al archivo de copia
	mov rdi, height
	mov edx, 4 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	call writeToCopy

	; Se ignora 2 bytes
	mov edi, 2 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	call ignoreBytes

	; Se copian los bytes ignorados al archivo de copia
	mov rdi, ingoredBytes
	mov edx, 2 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	call writeToCopy

	; Se lee el bitCount
	mov rdi, qword[fileDescriptor]
	mov rax, SYS_read
	mov rsi, bitCount
	mov edx, 2 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	syscall

	; Se copia el bitCount al archivo de copia
	mov rdi, bitCount
	mov edx, 2 ;  Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
	call writeToCopy

	; Calcular cantidad de bytes por pixel
	xor rax, rax ; Rompimiento de dependencia innecesaria
	mov ax, word [bitCount]
	shr ax, 3  ; Hacer un desplazamiento a la derecha de 3 bits (equivalente a dividir por 8)
	mov word [byteCount], ax

	; Calcular bytes restantes a ignorar
	xor rax, rax ; Rompimiento de dependencia innecesaria
	mov eax, dword[pixelDataOffset]
	sub eax, 30

	; Se ignoran los bytes restantes
	mov rdi, rax
	call ignoreBytes

	; Se copian los bytes ignorados al archivo de copia
	mov rdi, ingoredBytes
	mov rdx, rax
	call writeToCopy

	; Calculo de la cantidad de bytes a leer desde la matriz de pixeles
	xor rdx, rdx ; Rompimiento de dependencia innecesaria
	mov eax, dword[width]
	mul dword[height]
	mul dword[byteCount]
	mov rdx, rax

	; Se leen los bytes de la matriz de pixeles
	mov rdi, qword[fileDescriptor]
	mov rax, SYS_read
	mov rsi, pixelMatrix
	syscall

; Se aplica el filtro dependiendo del valor del filtro que se pasa desde C++
applyFilter:
	cmp byte[filter], 0
	je negativeFilter

	cmp byte[filter], 1
	je posFilter

	cmp byte[filter], 2
	je grayscaleFilter

	cmp byte[filter], 3
	je blackWhiteFilter

negativeFilter:
	; Se aplica el filtro negativo
	mov rdi, pixelMatrix
	call negFilter
	jmp copyMatrix

posFilter:
	; Se aplica el filtro posterize
	mov rdi, pixelMatrix
	mov rsi, [posterizationLevels]
	call posterizeFilter
	jmp copyMatrix

grayscaleFilter:
	; Se aplica el filtro grayScale
	mov rdi, pixelMatrix
	call grayScaleFilter
	jmp copyMatrix

blackWhiteFilter:
	; Se aplica el filtro blackAndWhite
	mov rdi, pixelMatrix
	call blackAndWhiteFilter

copyMatrix:
	; Se copian los bytes de la matriz de pixeles al archivo de copia
	mov rdi, pixelMatrix
	call writeToCopy

closeFiles:
	; Cerrar ambos archivos
	mov rdi, qword[fileDescriptor]
	call closeBMP
	mov rdi, qword[copyFileDescriptor]
	call closeBMP

finish:
	ret

;------------------------------------------------------

; Función que abre un archivo BMP
openBMP:	; recibe en rdi la dirección del path del archivo a abrir
	mov rax, SYS_open
	mov rsi, O_RDONLY
	syscall
	cmp rax, 0
	jl finish ; Uso de saltos en el caso menos probable al hacer una comparación
	mov qword[fileDescriptor], rax
	ret

; Función que cierra un archivo BMP
closeBMP: ; recibe en rdi el file descriptor del archivo a cerrar
	mov rax, SYS_close
	syscall
	ret

createBMP: ; recibe en rdi la dirección del path del archivo a crear
	mov rax, SYS_creat
	mov rsi, S_IRUSR | S_IWUSR
	syscall
	cmp rax, 0
	jl finish  ; uso de saltos en el caso menos probable al hacer una comparación
	mov qword[copyFileDescriptor], rax
	ret

ignoreBytes: ; recibe en rdi la cantidad de bytes a ignorar
	mov rdx, rdi
	mov rdi, qword[fileDescriptor]
	mov rax, SYS_read
	mov rsi, ingoredBytes
	syscall
	ret

writeToCopy:
; recibe en rdi la dirección del arreglo de bytes a escribir
; recibe en rdx la cantidad de bytes a escribir
	mov rax, SYS_write
	mov rsi, rdi
	mov rdi, qword[copyFileDescriptor]
	syscall
	ret

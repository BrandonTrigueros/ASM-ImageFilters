section .data

; --------------------- CONSTANTES ---------------------

	LF equ 10 ; cambio de linea
	NULL equ 0 ; caracter de final de string
	TRUE equ 1 ; verdadero
	FALSE equ 0 ; falso

	EXIT_SUCCESS equ 0 ; codigo de exito

	SYS_read equ 0 ; lectura
	SYS_write equ 1 ; escritura
	SYS_open equ 2 ; abrir archivo
	SYS_close equ 3 ; cerrar archivo
	SYS_exit equ 60 ; terminar
	SYS_creat equ 85 ; abrir/crear archivo

  OCREAT equ 0x40 ; crear archivo
	O_APPEND equ 0x400 ; agregar al final
	O_RDONLY equ 000000q ; solo lectura
	O_WRONLY equ 000001q ; solo escritura
	O_RDWR equ 000002q ; lectura y escritura
	
	S_IRUSR equ 00400q ; permisos de lectura
	S_IWUSR equ 00200q ; permisos de escritura

; --------------------- VARIABLES ---------------------

	path db "jessica.bmp", NULL
	copyPath db "copia.bmp", NULL
	posterizationLevels dq 5	; rango de 2 a 256

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
	extern negFilter
	extern posterizeFilter
	extern grayScaleFilter
	extern blackAndWhiteFilter
global _start
_start:
	; Se abre el archivo
	mov rdi, path
	call openBMP

	; Se crea el archivo de copia
	mov rdi, copyPath
	call createBMP

	; Se ignora 10 bytes
	mov rdi, 10
	call ignoreBytes

	; Se copian los bytes ignorados al archivo de copia
	mov rdi, ingoredBytes
	mov rdx, 10
	call writeToCopy
	

	; Se lee el offset de los datos de los pixeles
	mov rdi, qword[fileDescriptor]
	mov rax, SYS_read
	mov rsi, pixelDataOffset
	mov rdx, 4
	syscall

	; Se copia el offset al archivo de copia
	mov rdi, pixelDataOffset
	mov rdx, 4
	call writeToCopy

	; Se ignora 4 bytes
	mov rdi, 4
	call ignoreBytes

	; Se copian los bytes ignorados al archivo de copia
	mov rdi, ingoredBytes
	mov rdx, 4
	call writeToCopy

	; Se lee el ancho de la imagen
	mov rdi, qword[fileDescriptor]
	mov rax, SYS_read
	mov rsi, width
	mov rdx, 4
	syscall

	; Se copia el ancho de la imagen al archivo de copia
	mov rdi, width
	mov rdx, 4
	call writeToCopy

	; Se lee el alto de la imagenss
	mov rdi, qword[fileDescriptor]
	mov rax, SYS_read
	mov rsi, height
	mov rdx, 4
	syscall

	; Se copia el alto de la imagen al archivo de copia
	mov rdi, height
	mov rdx, 4
	call writeToCopy

	; Se ignora 2 bytes
	mov rdi, 2
	call ignoreBytes

	; Se copian los bytes ignorados al archivo de copia
	mov rdi, ingoredBytes
	mov rdx, 2
	call writeToCopy

	; Se lee el bitCount
	mov rdi, qword[fileDescriptor]
	mov rax, SYS_read
	mov rsi, bitCount
	mov rdx, 2
	syscall

	; Se copia el bitCount al archivo de copia
	mov rdi, bitCount
	mov rdx, 2
	call writeToCopy

	; Calcular cantidad de bytes por pixel
	xor rax, rax
	mov ax, word[bitCount]
	mov rbx, 8
	div rbx
	mov word[byteCount], ax

	; Calcular bytes restantes a ignorar
	xor rax, rax
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
	xor rdx, rdx
	mov eax, dword[width]
	mul dword[height]
	mul dword[byteCount]
	mov rdx, rax

	; Se leen los bytes de la matriz de pixeles
	mov rdi, qword[fileDescriptor]
	mov rax, SYS_read
	mov rsi, pixelMatrix
	syscall

aplicarFiltro:
	; Se aplica el filtro
	mov rdi, pixelMatrix
	;mov rsi, [posterizationLevels]
	call blackAndWhiteFilter

	; Se copian los bytes de la matriz de pixeles al archivo de copia
	mov rdi, pixelMatrix
	call writeToCopy

	; Cerrar ambos archivos
	mov rdi, qword[fileDescriptor]
	call closeBMP
	mov rdi, qword[copyFileDescriptor]
	call closeBMP

finish:
	mov rax, SYS_exit
	mov rdi, EXIT_SUCCESS
	syscall

;------------------------------------------------------

openBMP:	; recieves in rdi the path of the file to open
	mov rax, SYS_open
	mov rsi, O_RDONLY
	syscall
	cmp rax, 0
	jl finish
	mov qword[fileDescriptor], rax
	ret

closeBMP: ; recieves in rdi the file descriptor to close
	mov rax, SYS_close
	syscall
	ret

createBMP: ; recieves in rdi the path of the file to create
	mov rax, SYS_creat
	mov rsi, S_IRUSR | S_IWUSR
	syscall
	cmp rax, 0
	jl finish
	mov qword[copyFileDescriptor], rax
	ret

ignoreBytes: ; recieves in rdi the number of bytes to ignore
	mov rdx, rdi
	mov rdi, qword[fileDescriptor]
	mov rax, SYS_read
	mov rsi, ingoredBytes
	syscall
	ret

writeToCopy:
; recieves in rdi the direction of the bytes to write
; recieves in rdx the number of bytes to write
	mov rax, SYS_write
	mov rsi, rdi
	mov rdi, qword[copyFileDescriptor]
	syscall
	ret

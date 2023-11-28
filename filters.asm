; UNIVERSIDAD DE COSTA RICA
; CURSO: Lenguaje Ensamblador
; TAREA PROGRAMADA 2

; DESCRIPCIÓN:
;   Archivo que contiene las funciones para aplicar los filtros

; INTEGRANTES
;   Brandon Trigeuros Lara C17899
; 	Henry Rojas Fuentes C16812

section .data
  Coefficients dd 0.114, 0.587, 0.299, 0.0 ; azul, verde, rojo

section .text
global negFilter, posterizeFilter, grayScaleFilter, blackAndWhiteFilter 

negFilter:
	; recibe en rdi la direccion de la matriz de pixeles
	; recibe en rdx el numero de bytes a aplicar el filtro
	; funciona para bitCount = 24, byteCount = 3
	push rax
	push rcx
	mov rax, rdi
	mov rcx, rdx

	pixelLoopNeg:
		push rcx
		mov ecx, 3  ; Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits

		byteLoopNeg:
			mov bl, 255
			sub bl, byte[rax]
			mov byte[rax], bl
			inc rax
		loop byteLoopNeg

		pop rcx
	loop pixelLoopNeg
	
	pop rcx
	pop rax
	ret

posterizeFilter:
  ; recibe en rdi la direccion de la matriz de pixeles
  ; recibe en rdx el numero de bytes a aplicar el filtro
  ; recibe en rsi el numero de niveles de posterizacion
  ; funciona para bitCount = 24, byteCount = 3
  push rax
  push rcx
  push rbx

  mov rbx, rdi
  mov rcx, rdx

  call step

pixelLoopPos:
  push rcx
  mov ecx, 3 ; Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits

  byteLoopPos:
    xor rax, rax ; Rompimiento de dependencia innecesaria
    mov al, byte[rbx]
    div r10b
    mul r10b
    mov byte[rbx], al
    inc rbx
  loop byteLoopPos

  pop rcx
loop pixelLoopPos

  pop rbx
  pop rcx
  pop rax
  ret

step:
  ; recibe en rsi el numero de niveles de posterizacion
  push rax
  push rbx
  push rdx

  mov rbx, rsi
  sub rbx, 1
  xor rdx, rdx ; Rompimiento de dependencia innecesaria
  mov eax, 255 ; Escrituras en un registro de 32 bits siempre se amplían a cero en el registro de 64 bits
  div rbx

  mov r10b, al

  pop rdx
  pop rbx
  pop rax
  ret

grayScaleFilter:
	; recibe en rdi la direccion de la matriz de pixeles
  ; recibe en rdx el numero de bytes a aplicar el filtro
  ; funciona para bitCount = 24, byteCount = 3
	push rax
	push rcx
	mov rax, rdi
	mov rcx, rdx

  movups xmm10, [Coefficients]

	pixelLoopGray:

    call getGrayToneVectorized

		mov byte[rax], r8b; azul
		mov byte[rax+1], r8b; verde
		mov byte[rax+2], r8b; rojo
		add rax, 3
	loop pixelLoopGray
	
	pop rcx
	pop rax
	ret

getGrayToneVectorized:
  xorps xmm13, xmm13 ; Rompimiento de dependencia innecesaria

  movzx r8d, byte[rax+2] ; Restablece los bits altos de r8 y elimina la dependencia de cualquier valor previo de r8
  cvtsi2ss xmm13, r8d ; rojo
  orps xmm14, xmm13
  psllq xmm14, 32

  movzx r8d, byte[rax+1] ; Restablece los bits altos de r8 y elimina la dependencia de cualquier valor previo de r8
  cvtsi2ss xmm13, r8d; verde
  orps xmm14, xmm13
  pslldq xmm14, 4

  movzx r8d, byte[rax] ; Restablece los bits altos de r8 y elimina la dependencia de cualquier valor previo de r8
  cvtsi2ss xmm13, r8d; azul
  orps xmm14, xmm13

  vmulps xmm0, xmm14, xmm10

  xorps xmm13, xmm13 ; Rompimiento de dependencia innecesaria
  xorps xmm14, xmm14 ; Rompimiento de dependencia innecesaria

  vhaddps xmm1, xmm0, xmm14
  vhaddps xmm2, xmm1, xmm13

  xor r8, r8 ; Rompimiento de dependencia innecesaria
  cvtss2si r8d, xmm2
  ret

; si el tono de gris es mayor a 105, se pone blanco
blackAndWhiteFilter:
  ; recibe en rdi la direccion de la matriz de pixeles
  ; recibe en rdx el numero de bytes a aplicar el filtro
  ; funciona para bitCount = 24, byteCount = 3
  push rax
  push rcx
  mov rax, rdi
  mov rcx, rdx

  movups xmm10, [Coefficients]

  pixelLoopBlackAndWhite:
    call getGrayToneVectorized
    cmp r8b, 105
    jg setWhite
    mov byte[rax], 0
    mov byte[rax+1], 0
    mov byte[rax+2], 0
    jmp endIf
    setWhite:
      mov byte[rax], 255
      mov byte[rax+1], 255
      mov byte[rax+2], 255
    endIf:
    add rax, 3
  loop pixelLoopBlackAndWhite

  pop rcx
  pop rax
  ret

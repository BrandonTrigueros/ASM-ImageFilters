section .data
	BLUE_coeff dd 0.114
	GREEN_coeff dd 0.587
  RED_coeff  dd 0.299

section .text

global negFilter
global posterizeFilter
global grayScaleFilter
global blackAndWhiteFilter 

negFilter:
	; recieves in rdi the direction of the matrix of pixels
	; recieves in rdx the number of bytes to apply the filter
	; funciona para bitCount = 24, byteCount = 3
	push rax
	push rcx
	mov rax, rdi
	mov rcx, rdx

	pixelLoopNeg:
		push rcx
		mov rcx, 3

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
  ; recieves in rdi the direction of the matrix of pixels
  ; recieves in rdx the number of bytes to apply the filter
  ; recieves in rsi the number of levels of posterization
  ; funciona para bitCount = 24, byteCount = 3
  push rax
  push rcx
  push rbx

  mov rbx, rdi
  mov rcx, rdx

  call step

pixelLoopPos:
  push rcx
  mov rcx, 3

  byteLoopPos:
    xor rax, rax
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
  ; recieves in rsi the number of levels of posterization
  push rax
  push rbx
  push rdx

  mov rbx, rsi
  sub rbx, 1
  xor rdx, rdx
  mov rax, 255
  div rbx

  mov r10b, al

  pop rdx
  pop rbx
  pop rax
  ret



grayScaleFilter:
	; recieves in rdi the direction of the matrix of pixels
	; recieves in rdx the number of bytes to apply the filter
	; funciona para bitCount = 24, byteCount = 3
	push rax
	push rcx
	mov rax, rdi
	mov rcx, rdx

  movss xmm10, [BLUE_coeff]
  movss xmm11, [GREEN_coeff]
  movss xmm12, [RED_coeff]

	pixelLoopGray:

    call getGrayTone

		mov byte[rax], r8b; azul
		mov byte[rax+1], r8b; verde
		mov byte[rax+2], r8b; rojo
		add rax, 3
	loop pixelLoopGray
	
	pop rcx
	pop rax
	ret

getGrayTone:
  movzx r8d, byte[rax]
  cvtsi2ss xmm13, r8d ; azul
  movzx r8d, byte[rax+1]
  cvtsi2ss xmm14, r8d; verde
  movzx r8d, byte[rax+2]
  cvtsi2ss xmm15, r8d; rojo

  mulss xmm13, xmm10
  mulss xmm14, xmm11
  mulss xmm15, xmm12

  addss xmm13, xmm14
  addss xmm13, xmm15

  xor r8, r8
  cvtss2si r8d, xmm13
  ret

; if getGrayTone > 100 then 255 else 0
blackAndWhiteFilter:
  ; recieves in rdi the direction of the matrix of pixels
  ; recieves in rdx the number of bytes to apply the filter
  ; funciona para bitCount = 24, byteCount = 3
  push rax
  push rcx
  mov rax, rdi
  mov rcx, rdx

  movss xmm10, [BLUE_coeff]
  movss xmm11, [GREEN_coeff]
  movss xmm12, [RED_coeff]

  pixelLoopBlackAndWhite:
    call getGrayTone
    cmp r8b, 100
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

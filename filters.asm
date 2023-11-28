section .data
  Coefficients dd 0.114, 0.587, 0.299, 0.0

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
  xorps xmm13, xmm13

  movzx r8d, byte[rax+2]
  cvtsi2ss xmm13, r8d ; rojo
  orps xmm14, xmm13
  psllq xmm14, 32

  movzx r8d, byte[rax+1]
  cvtsi2ss xmm13, r8d; verde
  orps xmm14, xmm13
  pslldq xmm14, 4

  movzx r8d, byte[rax]
  cvtsi2ss xmm13, r8d; azul
  orps xmm14, xmm13

  vmulps xmm0, xmm14, xmm10

  xorps xmm13, xmm13
  xorps xmm14, xmm14

  vhaddps xmm1, xmm0, xmm14
  vhaddps xmm2, xmm1, xmm13

  xor r8, r8
  cvtss2si r8d, xmm2
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

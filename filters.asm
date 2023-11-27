section .text
global negFilter
global posterizeFilter
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

  call paso

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

paso:
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
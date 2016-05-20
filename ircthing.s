BITS 64

section .text
global _start

writeloop:
	xor rax, rax
	mov rdi, 0
	mov rsi, buf
	mov rdx, 512
	syscall

	mov rdx, rax
	mov [buf+rdx+1], byte 0dh
	mov [buf+rdx+2],byte 0ah

	mov rax, 1
	mov dil, [sock]
	mov rsi, buf
	syscall

	jmp writeloop

msglen:
	xor rax, rax
	dec rsi
	msglenloop:
	inc rsi
	inc rax
	cmp [rsi], byte 0ah
	jne msglenloop
	;dec rax
	ret

connectionz:
	mov rax, 41; socket
	mov rdi, 2;AF_INET
	mov rsi, 1;SOCK_STREAM
	mov rdx, 0
	syscall

	mov [sock], al;save the sock fd

	mov rax, 42; connect
	mov dil, [sock];8 bits o rdi
	mov rsi, destaddr
	mov rdx, 16
	syscall
	ret
	; We've got a connection!

register:
	mov rax, 1
	mov dil, [sock]
	mov rsi, regusermsg
	mov rdx, regusermsglen
	syscall
	ret

_start:
	call connectionz
	call register

	mov rax, 57
	syscall
	cmp rax, 0
	je writeloop

	mainloop:
		xor rax, rax
		mov dil, [sock];8 bits o rdi
		mov rsi, buf
		mov rdx, 512
		syscall
		push rax

		cmp rax, 0
		jle exit;EOF or error reading
		
		mov rdx, rax;Prints it out, I think
		mov rax, 1
		mov rdi, 1
		mov rsi, buf
		syscall
		
		pop rax
		mov rdx, rax
		dec rsi
		pingscanloop:
			dec rax
			cmp rax, 0
			jle mainloop
			inc rsi
			cmp [rsi], dword "PING"
			jne pingscanloop
			cmp [rsi+5], byte ' '
			jne pingscanloop

			mov [rsi+1], byte 'O'
			
			push rsi
			call msglen
			mov rdx, rax
			pop rsi

			mov rax, 1
			mov dil, [sock]
			;mov rsi, buf
			syscall

			mov rax, 1
			mov rdi, 1
			;mov rsi, buf
			syscall
			
			jmp mainloop
			
		
	
	exit:
		mov rax, 60
		mov rdi, 137
		syscall


	ret; We didn't exit! Panic!
	hlt
	mov [0], byte 0
	mov rax, [0]
	db "efbeadde"

section .data
	sock:
		db 00, 00

	regusermsg: db "USER asmbot 0 127.0.0.1 asmbot", 0x0d, 0x0a, "NICK asmbot", 0x0d, 0x0a
	regusermsglen: equ $-regusermsg

	destaddr:
		db 0x02, 0x00; AF_INET
		db 0x1a, 0x0b; 6667 in network byte order
		db 127, 0, 0, 1
		;db 54,228,211,168
		db 0,0,0,0, 0,0,0,0

		
section .bss
	buf: resb 512
		

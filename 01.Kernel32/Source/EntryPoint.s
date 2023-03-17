[ORG 0x00]
[BITS 16]

SECTION .text

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;code section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:
	mov ax, 0x1000

	mov ds, ax
	mov es, ax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Activate A20 gate
; when Convert using BIOS is failed try to convert system control port
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Activate using BIOS Service
	mov ax, 0x2401
	int 0x15

	jc .A20GATEERROR
	jmp .A20GATESUCCESS

.A20GATEERROR:
;when error occured, try to convert System Control Port
	in al, 0x92
	or al, 0x02
	and al, 0xFE
	out 0x92, al

.A20GATESUCCESS:
	cli
	lgdt [ GDTR ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Enter to Secure mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, 0x4000003B
	mov cr0, eax


	jmp dword 0x18: (PROTECTEDMODE -$$ + 0x10000 )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;Enter to Secure mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 32]
PROTECTEDMODE:
	mov ax, 0x20
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	;Create 64KB Stack to 0x00000000~0X0000FFFF
	mov ss, ax
	mov esp, 0xFFFE
	mov ebp, 0xFFFE

	;print convert message to screen
	push ( SWITCHSUCCESSMESSAGE - $$ + 0x10000 )
	push 2
	push 0
	call PRINTMESSAGE
	add esp, 12




	jmp dword 0x18: 0x10200

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Function Code section
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; function printing message
	; x, y, message to stack

	PRINTMESSAGE:
		push ebp
		mov ebp, esp
		push esi
		push edi
		push eax
		push ecx
		push edx

		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; Calculate adress of video adress
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		; Line adress to use y
		mov eax, dword [ ebp + 12 ]
		mov esi, 160
		mul esi
		mov edi, eax

		; Final adress to use x after multiple 2
		mov eax, dword [ ebp + 8 ]
		mov esi, 2
		mul esi
		add edi, eax



		;adress of print message
		mov esi, dword [ ebp + 16 ]

.MESSAGELOOP:
	mov cl, byte [ esi ]

	cmp cl, 0
	je .MESSAGEEND

	mov byte [ edi + 0xB8000 ], cl

	add esi, 1
	add edi, 2
	jmp .MESSAGELOOP

.MESSAGEEND:
	pop edx
	pop ecx
	pop eax
	pop edi
	pop esi
	pop ebp
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Data Section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

align 8, db 0

dw 0x0000

GDTR:
	dw GDTEND - GDT - 1
	dd ( GDT - $$ + 0x10000 )


GDT:
	NULLDescriptor:
		dw 0x0000
		dw 0x0000
		db 0x00
		db 0x00
		db 0x00
		db 0x00

	IA_32eCODEDESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x9A
		db 0xAF
		db 0x00

	IA_32DATADESCRIPTROR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x92
		db 0xAF
		db 0x00

	CODEDESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x9A
		db 0xCF
		db 0x00

	DATADESSCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x92
		db 0xCF
		db 0x00
GDTEND:

SWITCHSUCCESSMESSAGE: db 'Switch To Protected Mode Success!', 0

times 512 - ( $ - $$ ) db 0x00











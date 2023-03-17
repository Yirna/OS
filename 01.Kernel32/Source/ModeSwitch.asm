[BITS 32]

global kReadCPUID, kSwitchAndExecute64bitKernel

SECTION .text


;return CPUID
;Parameter: DWORD dwEAX, DWORD* pdwEAX,* pdwEBX,* pdwECX,*pdwEDX
kReadCPUID:
	push ebp
	mov ebp, esp
	push eax
	push ebx
	push ecx
	push edx
	push esi


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;EAX -> excute CPUID
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	mov eax, dword [ ebp + 8 ]
	cpuid

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; save return value to parameter
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*pdwEAX
	mov esi, dword [ ebp + 12 ]
	mov dword [ esi ], eax

;*pdwEBX
	mov esi, dword [ ebp + 16 ]
	mov dword [ esi ],ebx

;*pdwECX
	mov esi, dword [ ebp + 20 ]
	mov dword [ esi ], ecx

;*pdwEDX
	mov esi, dword [ ebp + 24 ]
	mov dword [ esi ], edx

	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret

;Convert to IA-32e and conduct 64bit kernel
;Parameter : none
kSwitchAndExecute64bitKernel:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Setting PAE bit of CR4 control register
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, cr4
	or eax, 0x20
	mov cr4, eax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;acrivate cache and PML4 Table adress of CR3 Control Register
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, 0x100000
	mov cr3, eax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;To set IA32_EFER.LME to 1, and Activate IA-32e mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ecx, 0xC0000080 ; Save adress of IA32-EFER MSR reg
	rdmsr		;read MSR reg

	or eax, 0x0100 	;Setting LME bit(8bit) to 1 at IA32_EFER MSR's under 32bit
				;saved at EAX reg
	wrmsr		;write to MSR reg

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Setting CR0 Control reg to NW bit(bit 29) = 0, CD bit(bit 30) = 0, PG bit(bit 31) = 1,
;Activate Cache, Paging function
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov eax, cr0			;Save CR0 Control reg to EAX reg
	or eax, 0xE0000000		;Set NW bit(bit 29), CD bit(bit 30), PG bit(bit 31) to 1
	xor eax, 0x6000000		;Xor calculate NW bit(bit 29) and CD bit(bit 30) to set 0
	mov cr0, eax			;Save setting value - NW bit = 0, CD bit = 0, PG bit = 1 to CR0 reg

	jmp 0x08:0x200000		;Exchange CS segment Selector to IA-32e mode Code segment Discriptor
							;and move to 0x200000(2MB) adress


	jmp $





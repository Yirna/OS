[ORG 0x00]			;Set Code start adress to 0x00
[BITS 16]			;Set Code to 16bits

SECTION .text		;define text section

jmp 0x07C0:START	;Infinite Loop in current location


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Setting value relative with MINT64 OS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TOTALSECTORCOUNT:	dw	0x02	;size of OS image file except Bootloader
								;able to Maximum 1152Sector(0x90000byte)
KERNEL32SECTORCOUNT: dw 0x02
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; code Segmant
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:
	mov ax, 0x07C0	;Convert start adress about BootLoader(0x7C00) to Secment Register value
	mov ds, ax		;Setting to DS Segment Register
	mov ax, 0xB800	;Convert start adress about Video Memor(0xB800) to Segment Register
	mov es, ax		;Setting to ES Segment Register

	; Create 64KB size Stack to 0x0000:0000~0x0000:FFFF region
	mov ax, 0x0000	;Convert start adress about Stack Segment(0x0000) to Segment Register
	mov ss, ax		;Setting to SS Segment Register
	mov sp, 0xFFFE	; Setting Adress of SP Register to 0xFFFE
	mov	bp, 0xFFFE 	; Setting Adress of BP Register to 0xFFFE
					; Solution of why not 0xFFFF http://jsandroidapp.cafe24.com/xe/index.php?mid=qna&search_target=title&search_keyword=0xfffe&document_srl=5442

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Clear all of display, Setting Color to light Green
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov si,	0		;Initialize SI Register(string source index register)

.SCREENCLEARLOOP:					;Clear the Display
	mov byte [ es: si ], 0
	;Delete the character by copying 0 to the address where the character is located in the video memory.
	mov byte [ es: si + 1 ], 0x0A
	;Copy 0x0A(Black Background, light green) to Address where attributes of video memory are located
	add si, 2						; 문자와 속성을 설정했으므로 다음 위치로 이동

	cmp si, 80 * 25 * 2				; 화면의 전체 크기는 80 문자 * 25 라인임
									; 출력한 문자의 수를 의미하는 SI 레지스터와 비교
	jl .SCREENCLEARLOOP				; SI 레지스터가 80 * 25 * 2보다 작다면 아직 지우지
									; 못한 영역이 있으므로 .SCREENCLEARLOOP 레이블로 이동

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 화면 상단에 시작 메시지 출력
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push MESSAGE1					;출력할 메시지의 어드레스를 스택에 삽입
	push 0							; 화면 Y 좌표(0)를 스택에 삽입
	push 0							; 화면 X 좌표(0)를 스택에 삽입
	call PRINTMESSAGE				; PRINTMESSAGE 함수 호출
	add sp, 6						; 삽입한 파라미터 제거

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; OS 이미지를 로딩한다는 메시지 출력
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push IMAGELODAINGMESSAGE		; 출력할 메시지의 어드레스를 스택에 삽입
	push 1							; 화면 Y 좌표(1)를 스택에 삽입
	push 0							; 화면 X 좌표(0)를 스택에 삽입
	call PRINTMESSAGE				; PRINTMESSAGE 함수 호출
	add sp, 6						; 삽입한 파라미터 제거

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 디스크에서 OS 이미지를 로딩
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 디스크를 읽기 전에 먼저 리셋
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESETDISK:							;Start of Reseting the Disk
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; BIOS Reset Function 호출
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;서비스 번호 0, 드라이브 번호(0=Floppy)
	mov ax, 0
	mov dl, 0
	int 0x13
	; 에러가 발생하면 에러 처리로 이동
	jc HANDLEDISKERROR

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 디스크에서 섹터를 읽음
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 디스크의 내용을 메모리로 복사할 어드레스(ES:BX)를 0x10000으로 설정
	mov si, 0x1000					; OS 이미지를 복사할 어드레스(0x10000)를
									; 세그먼트 레지스터 값으로 변환
	mov es, si						; ES 세그먼트 레지스터에 값 설정
	mov bx, 0x0000					; BX 레지스터에 0x0000을 설정하여 복사할
									; 어드레스를 0x1000:0000(0x10000)으로 최종 설정

	mov di, word [ TOTALSECTORCOUNT ] ; 복사할 OS 이미지의 섹터 수를 DI 레지스터에 설정

READDATA:							;Start of the Code reading Disk
	;check read all sector
	cmp di, 0						; 복사할 OS 이미지의 섹터 수를 0과 비교
	je READEND						; 복사할 섹터 수가 0이라면 다 복사 했으므로 READEND로 이동
	sub di, 0x1						; 복사할 섹터 수를 1 감소

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; BIOS Read Function 호출
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	mov ah, 0x02					; BIOS 서비스 번호 2(Read Sector)
	mov al, 0x1						; 읽을 섹터 수는 1
	mov ch, byte [ TRACKNUMBER ]	; 읽을 트랙 번호 설정
	mov cl, byte [ SECTORNUMBER ]	; 읽을 섹터 번호 설정
	mov dh, byte [ HEADNUMBER ]		; 읽을 헤드 번호 설정
	mov dl, 0x00					; 읽을 드라이브 번호(0=Floppy) 설정
	int 0x13						; 인터럽트 서비스 수행
	jc HANDLEDISKERROR				; 에러가 발생했다면 HANDLEDISKERROR로 이동

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 복사할 어드레스와 트랙, 헤드, 섹터 어드레스 계산
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	add si, 0x0020


	mov es, si


	mov al, byte [ SECTORNUMBER ]
	add al, 0x01
	mov byte [ SECTORNUMBER ], al
	cmp al, 37
	jl READDATA

	xor byte [ HEADNUMBER ], 0x01
	mov byte [ SECTORNUMBER ], 0x01

	cmp byte [ HEADNUMBER ], 0x00
	jne READDATA

	add byte [ TRACKNUMBER ], 0x01
	jmp READDATA

READEND:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; OS 이미지가 완료되었다는 메시지를 출력
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push LOADINGCOMPLETEMESSAGE
	push 1
	push 20
	call PRINTMESSAGE
	add sp, 6
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 로딩한 가상 OS 이미지 실행
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	jmp 0x1000:0x0000


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 함수 코드 영역
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HANDLEDISKERROR:
	push DISKERRORMESSAGE
	push 1
	push 20
	call PRINTMESSAGE

	jmp $

	; 메시지를 출력하는 함수
	; PARAM: x 좌표, y 좌표, 문자열
PRINTMESSAGE:
	push bp
	mov bp, sp


	push es
	push si
	push di
	push ax
	push cx
	push dx

	mov ax, 0xB800

	mov es, ax

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; X, Y의 좌표로 비디오 메모리의 어드레스를 계산함
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Y 좌표를 이용해서 먼저 라인 어드레스를 구함
	mov ax, word [ bp + 6 ]	; 파라미터 2(화면 좌표 Y)를 AX 레지스터에 설정
	mov si, 160				; 한 라인의 바이트 수(2 * 80 컬럼)를 SI 레지스터에 설정
	mul si					; AX 레지스터와 SI 레지스터를 곱하여 화면 Y 어드레스 계산
	mov di, ax				; 계산된 화면 Y 어드레스를 DI 레지스터에 설정

	; X 좌표를 이용해서 2를 곱한 후 최종 어드레스를 구함
	mov ax, word [ bp + 4 ]	; 파라미터 1(화면 좌표 X)를 AX 레지스터에 설정
	mov si, 2				; 한 문자를 나타내는 바이트 수(2)를 SI 레지스터에 설정
	mul si					; AX 레지스터와 SI 레지스터를 곱하여 화면 X 어드레스를 계산
	add di, ax				; 화면 Y 어드레스와 계산된 X 어드레스를 더해서
							; 실제 비디오 메모리 어드레스를 계산

	; Adress of String printed
	mov si, word [ bp + 8 ]

.MESSAGELOOP:
	mov cl, byte [ si ]

	cmp cl, 0
	je .MESSAGEEND


	mov byte [ es: di ], cl

	add si, 1
	add di, 2



	jmp .MESSAGELOOP

.MESSAGEEND:
	pop dx
	pop cx
	pop ax
	pop di
	pop si
	pop es
	pop bp
	ret


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 데이터 영역
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Start BootLoader
MESSAGE1:	db 'MINT64 OS Boot Loader Start...', 0


DISKERRORMESSAGE:	db 'DISK ERROR!', 0
IMAGELODAINGMESSAGE: db 'OS Image Loading...', 0
LOADINGCOMPLETEMESSAGE: db 'Complete!', 0


 ;디스크 읽기에 관련된 변수들
SECTORNUMBER:	db 0x02
HEADNUMBER:		db 0x00
TRACKNUMBER:	db 0x00

times 510 - ( $ - $$ )	db	0x00	;$: current line's adress
									;$:: this section's(.text) start adress
									;$-$$: offset relative to the current section
									;510 - ( $ - $$ ): from current adress to adress 510
									;db 0x00: declare 1byte and value is 0x00
									;time: repeat
									;Fill from current adress to address 510 with 0x00

db 0x55								;declare 1byte and value is 0x55
db 0xAA								;declare 1byte and value is 0xAA
									; marks BootSector to write 0x55, 0xAA to adress 511, 512

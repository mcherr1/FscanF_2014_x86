	;; Program that reads in a file. Then parses the file for strings floats and ints
	;; and uses the floating point stack to convert these into floats and int.
	;; It prints these their respective files. Finally
	;; it finds the number of ints floats and strings, the sum of the ints,
	;; and the min and max float and prints them to screen.

	;; Code found in Cfunctions and Getting command line arguments when using GCC 
	;; Found at: http://www.csee.umbc.edu/~cpatel2/links/310/ was used in this code 
	;; and is cotained in commonCode.asm
	;;
	;; Compile Using:
	;;
	;; nasm -f elf project3.asm
	;; gcc -m32 "project3".o
	;; a.out "file.txt"
	
%include "common_code.asm"
	
extern fprintf
extern printf
extern fopen
extern fclose

%define STDIN 0
%define STDOUT 1
%define SYSCALL_EXIT  1
%define SYSCALL_READ  3
%define SYSCALL_WRITE 4
%define SYSCALL_OPEN  5
%define buff 260000

	
section .data
		
ioutfile:  dd "project3_int.out",0
foutfile:  dd "project3_float.out",0
soutfile:  dd "project3_string.out",0

myfloatsum db 'this is the sum: %f', 10, 0
myfloathigh db'the largest float is: %e', 10, 0
myfloatlow db 'the smallest float is: %e', 10, 0

write_char:   db 'w', 0		; used in fopen
read_char:	db 'r', 0		; used in fopen
filename:	dd 0			; address of the pointer to filename
file_pointer:	dd 0			; filepointer
number:	dd 0			; number of interger scanned

intfprintf	db "%d",10,0
floatfprintf	db "%e",10,0
stringfprintf	db "%c",0
count:		dd 0			; number for the count variable
counter:	dd 0			; number for current loop counter	

tempChar	db 0			; hold the character
floatCounter	dd 0			; float counter
expoSign	dd 0			; exponent float counter sign
numFloats	dd 0			; number of floats strings and ints
numStrings	dd 0
numInts	dd 0
floatMax	dq 0			;float min and max
floatMin	dq 0			
ten		dd 0			; ten to multiply by
sum		dq 0			; sum of all ints
isneg		dd 0			; is it negative
cNum:		dd 0			; the current number	
fNum		dd 0			; temporary storage for our float operation
fFinal		dq 0			; the float after operation
section .bss
aray		resb 260000		; 260000bytes of reserved memory
fin		resb 1			; file handle
numbers	resb 256000		; stores current numbers
adress		resd 1			; current address
file_open_i:	resb 4 
file_open_f:	resb 4 
file_open_s:	resb 4 
	
section .text
global main 

;=====================================
;Opens file and read into an array
;=====================================

main:
	

getFile:
	;; Get the filename, pointer to input filename is returned, will equal 0 for an invalid filname
	push	dword filename	; Push address of the pointer to the filename
	call	GetCommandLine	; Return address pushed to stack, Go to line 72, GetCommandLine
	add	esp, 4			; Resets stack value (equivalent to 'pop' inst)

	mov eax, SYSCALL_OPEN 
	mov ebx, [filename]
	mov ecx, 0
	mov edx, 0777
	int     080h 

	mov [fin], eax

	mov eax, SYSCALL_READ
	mov ebx, [fin]
	mov ecx, aray
	mov edx, buff
	int     080h 
	
;; open all three files
	push dword write_char
	push dword ioutfile
	call fopen
	add esp,8
	cmp eax, 0
	je Exit
	mov [file_open_i], eax


	push dword write_char
	push dword soutfile
	call fopen
	add esp,8
	cmp eax, 0
	je Exit
	mov [file_open_s], eax

	push dword write_char
	push dword foutfile
	call fopen
	add esp,8
	cmp eax, 0
	je Exit
	mov [file_open_f], eax

;; point to pointer of file to increment
	mov edi, aray
	mov [adress], edi

;; mov 10 into 10
	mov eax, 10
	mov [ten], eax

;; set sum and num of floats ints and strings to zero to zero
	mov dword [sum], 0
	mov dword [numFloats], 0
	mov dword [numStrings], 0
	mov dword [numInts], 0

	
;; gets first input for counter
	call CounterNumber
	mov eax, dword [cNum]
	mov [count], eax

;; List of quick generated Strings I use

Make_Local_Str temp_gcl3_len, temp_gcl3_str, 'Number of strings: %d', 10, 0
Make_Local_Str temp_gcl4_len, temp_gcl4_str, 'Number of ints: %d', 10, 0
Make_Local_Str temp_gcl5_len, temp_gcl5_str, 'Number of floats: %d', 10, 0


mainLoop:
	call IncArray			;get rid of newline character from our last run
	call GetNext			; get the data and do work
	mov ecx, dword [count]
	dec ecx
	jz mainLooptoPrint		;no more get outa here and print
	mov [count], ecx
	jmp mainLoop
mainLooptoPrint:
	fld qword [sum]		;print the sum of the ints
	sub esp, byte 8
       fstp qword [esp]
       push dword myfloatsum
       call printf
       add esp, byte 12

	fld qword [floatMax]		;print the highest float
	sub esp, byte 8
       fstp qword [esp]
       push dword myfloathigh
       call printf
       add esp, byte 12

	fld qword [floatMin]		;print the lowest float
	sub esp, byte 8
       fstp qword [esp]
       push dword myfloatlow
       call printf
       add esp, byte 12

	;;print the number of strings floats and ints
	mov eax, dword [numStrings]
	C_Sys_Call printf, 2, temp_gcl3_str, eax

	mov eax, dword [numInts]
	C_Sys_Call printf, 2, temp_gcl4_str, eax

	mov eax, dword [numFloats]
	C_Sys_Call printf, 2, temp_gcl5_str, eax
	
	;; close the files
	push dword [file_open_s]
	call fclose
	add esp, 4

	push dword [file_open_i]
	call fclose
	add esp, 4

	push dword [file_open_f]
	call fclose
	add esp, 4
;;Exiting
Exit:	
	mov     EAX, SYSCALL_EXIT       
       mov     EBX, 0                
       int     080h  



;=====================================
;Converts a int
;=====================================

covertToInt:
	xor ecx, ecx				; set counter to zero
	mov [cNum], ecx			; clearspace in ecx
	mov ecx, dword [counter]		; move the counter into ecx
	dec ecx				; dec the counter by 1
	xor edx, edx				; clear edx
startConvert:
	cmp edx, 2				;if its looped twice add to make room on stack
	jge addInt
intWasAdded:
	mov ebx, ecx				;move ecx into ebx as a secondary counter
	mov al, [numbers+edx]		;move the value plus edx counter into al
	mov [cNum], al			;move al into cNum
	fild dword [cNum]			;push the value in al onto the flaot point stack 
	cmp ecx, 0				;check if the counter hit zero and get ready to add if so
	je addInt2
multi10:
	fild dword [ten]			;push ten on the stack
	fmul					;multiply them together
	dec ebx				;lower the inner loop counter
	jnz multi10				;if its not zero keep multiplying by 10
	inc edx				;increase edx to get next value
	dec ecx				;lower our main loop counter
	jmp startConvert			
addInt:
	fadd					;add the numbers on the stack
	jmp intWasAdded
addInt2:
	cmp edx, 1				;if it looped at least once add the number 
	jl addInt3				;otherwise nothing to add
	fadd					;add the last number
addInt3:
	fild dword [isneg]			;push isneg on the stack and multiply to get a neg value if so
	fmul
	fistp dword [cNum]			;pop into cNum
	mov eax, dword [cNum]		;error checking
doneConvert:
	ret

;=====================================
;Adds to to total sum
;=====================================
intAddToSum:
	fild dword [cNum]			;load the current sum
	fld qword [sum]
	fadd					;add and pop back into sum
	fstp qword [sum]
	ret

;=====================================
;Gets the next string or number or float
;=====================================
GetNext:
	call getByte				;get the current byte
	cmp al, 65
	jge isString				;is it a string
	call imANum				;otherwise its a number
	jmp endGetNext			
isString:
	call imAString
endGetNext:
	ret
	

;=====================================
;The next characters are a string
;=====================================
imAString:
	push eax
	pop eax
StringLoop:
	cmp al, 10			;found a newline or end of file  null term stop scanning
	je endOfString
	cmp al, 0			
	je endOfString
	xor ebx, ebx			;clear ebx and print the character
	mov [tempChar], al
	mov ebx, [tempChar]
	push dword ebx		;print string to file
       push dword stringfprintf
       push dword [file_open_s]
       call fprintf
       add esp, 12
	call IncArray
	call getByte
	jmp StringLoop
endOfString:
	mov ebx, 10			;print newline character
	push dword ebx
       push dword stringfprintf
       push dword [file_open_s]
       call fprintf
       add esp, 12
	mov ebx, [numStrings]	;increment String Counter
	inc ebx
	mov [numStrings], ebx
	ret

;=====================================
;The next characters is a number
;=====================================
imANum:
	mov edi, numbers		;move our storage facility into edi
	xor ecx, ecx			;set the counter to 0 to start
	mov [isneg], dword 1		;set isneg to 1
	cmp al, 45
	jne NonNegative		;check if number is negative
	mov [isneg], dword -1
	call IncArray
	call getByte
NonNegative:
	cmp al, 46
	je decPoint			;if there is a decimal point its a float
	cmp al, 10
	je endOfInt			;found a newline or end of file  null term stop scanning
	cmp al, 0
	je endOfInt
	sub al, 48			;get the number
	xor edx, edx			;clear the space in numbers for our new character(num)
	mov [edi], edx
	mov [edi], byte al
	call IncArray			;get the next byte
	call getByte
	inc edi			;incrment numbers for a new character
	inc ecx			;incrment our counter
	jmp NonNegative		;loop again
decPoint:
	call imAFloat
	jmp endimANum
endOfInt:
	mov ebx, [numInts]		;increment Int Counter
	inc ebx
	mov [numInts], ebx
	mov dword [counter], ecx	;the loop counter for the number of variables
	call covertToInt		;call these functions to covert to an int add to sum
	call intAddToSum		;and store the number in cNum
PrintTheInt:
	push dword [cNum]		;print the int to file
       push dword intfprintf
       push dword [file_open_i]
       call fprintf
       add esp, 12
endimANum:
	ret

;=====================================
;Used for only the first number
;Gets the number of things read in
;=====================================
CounterNumber:
	call getByte
imANum1:
	mov edi, numbers		;move our storage facility into edi
	xor ecx, ecx			;set the counter to 0 to start
	mov [isneg], dword 1		;set isneg to 1
	cmp al, 45
	jne NonNegative1		;check if number is negative
	mov [isneg], dword -1
	call IncArray
	call getByte
NonNegative1:
	cmp al, 10
	je endOfInt1			;found a newline or end of file  null term stop scanning
	cmp al, 0
	je endOfInt1
	sub al, 48			;get the number
	xor edx, edx			;clear the space in numbers for our new character(num)
	mov [edi], edx
	mov [edi], byte al
	call IncArray			;get the next byte
	call getByte
	inc edi			;incrment numbers for a new character
	inc ecx			;incrment our counter
	jmp NonNegative1		;loop again
endOfInt1:
	mov dword [counter], ecx	;the loop counter for the number of variables
	call covertToInt		;call these functions to covert to an int
	ret


;=====================================
;The next characters is a Float
;=====================================
imAFloat:
	xor ebx,ebx			;set our post decimal loop counter to zero
RemoveDecimal:
	call IncArray			;get the next byte initially removing the decimal
	call getByte
	cmp al, 69
	je PreExpWork			;check for the E+/-xx
	sub al, 48			;get the number
	xor edx, edx			;clear the space in numbers for our new character(num)
	mov [edi], edx
	mov [edi], byte al
	inc edi			;incrment numbers for a new character
	inc ecx			;incrment our counter
	inc ebx			;increment our post decimal loop counter
	jmp RemoveDecimal		;loop again
PreExpWork:
	mov [counter], ecx		;get our counter
	mov [floatCounter], ebx	;how many values past the decimal did we ignore
	call covertToInt		;turn our values into a number
	mov eax, dword [cNum]
	mov dword [fNum], eax	;put our number processed into fNum temporarly
ExpWork:
	mov [isneg], dword 1		;set isneg to 1
	call IncArray			;get the next byte removing the E
	call getByte
	cmp al, 45
	jne NonNegExp
	mov [isneg], dword -1	;its negative
NonNegExp:
	mov edi, numbers		;move our storage facility into edi
	xor ecx, ecx			;set the counter to 0 to start
NonNegExp2:				;find the exp number
	call IncArray
	call getByte
	cmp al, 10
	je endOfExp			;found a newline or end of file  null term stop scanning
	cmp al, 0
	je endOfExp			
	sub al, 48			;get the number
	xor edx, edx			;clear the space in numbers for our new character(num)
	mov [edi], edx
	mov [edi], byte al
	inc edi			;incrment numbers for a new character
	inc ecx			;incrment our counter
	jmp NonNegExp2		;loop again
endOfExp:
	mov [counter], ecx
	call covertToInt		;get our exponent number in cNum
	mov eax, dword [cNum]	;find the total difference between the two 
	mov ebx, dword [floatCounter]
	sub eax, ebx
	mov dword [cNum], eax
	call makeAFloat
	mov ebx, [numFloats]		;increment Float Counter
	inc ebx
	mov [numFloats], ebx
	ret

;=====================================
;Makes a float from the int value
;=====================================
makeAFloat:
	mov ecx, dword[cNum]		;get the counter
	fild dword [fNum]		;put the number on the floating point stack
	cmp ecx, 0			;check if no division or mult is nessessary
	je compareFloats
	cmp ecx, 0			;divide or multiply
	jl divBy10
mulBy10:				;multiply by 10 x times
	fild dword [ten]	
	fmul
	dec ecx
	jz compareFloats
	jmp mulBy10
divBy10:				;divide by 10 x times
	fild dword [ten]	
	fdiv
	inc ecx
	jz compareFloats
	jmp divBy10
compareFloats:			;compare floats
	fcom qword [floatMax]
	fstsw ax
	sahf
	jb compareFloatsMin		;max fist
	fst qword [floatMax]
compareFloatsMin:
	fcom qword [floatMin]	;then min
	fstsw ax
	sahf
	ja endMakeFloat
	fst qword [floatMin]
endMakeFloat:				;get outa here and print the float
	sub esp, 8			;print the float to file
	fstp qword [esp]
	push dword floatfprintf
	push dword [file_open_f]
	call fprintf
	add esp, byte 16
	ret


;=====================================
;Increments array address
;=====================================
IncArray:
	mov esi, [adress]		;increment the adress of the array
	add esi, byte 1
	mov [adress], esi
	ret

;=====================================
;Grabs a character from the array to be
;parsed from nums
;=====================================
getByte:
	mov esi, [adress]		;grab a byte
	mov al, byte [esi]
	ret




	


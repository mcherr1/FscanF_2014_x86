%include "mine.inc"

extern printf

         section .text


;=====================================
;Common Code
;=====================================

GetCommandLine:

	;; Macros to move esp into ebp and push regs to be saved
         Enter 0
         Push_Regs ebx, ecx, edx

	;; Initially sets [filename] to 0, remains 0 if there's an error
         mov ebx, [ebp + 8]
         mov [ebx], dword 0

	;; Get argc (# of arguments)
         mov ecx, [ebp + 16]

	;; Checks the value of argc, should be 2 (a.out and input.txt), includes the if statement macro
         cmp ecx, 2
         if ne
            jmp gcl_done
         endif

	;; Get argv[0] ("a.out"/"cfunctions" or the executable, this is not used in the project)
	;; Consult slide 6 of Stack Basics... lecture
	 mov ecx, [ebp + 20]   	;  ptr to args ptr
	 mov ebx, [ecx]		;  argv[0]

	;; Get argv[1] ("input.txt")
         mov ecx, [ebp + 20]	; ptr to args ptr
         mov ebx, [ecx + 4]	; argv[1]

	;; Set the filename pointer arg on the stack to the address of the filename
         mov edx, [ebp + 8]
         mov [edx], ebx

gcl_done:
	;; Macros to return
         Pop_Regs ebx, ecx, edx
         Leave

	;; Return
         ret


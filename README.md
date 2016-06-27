# FscanF_2014_x86
assembler project

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
	;; nasm -f elf project_fscanf_assembler.asm
	;; gcc -m32 "project_fscanf_assembler".o
	;; a.out "file.txt"
	

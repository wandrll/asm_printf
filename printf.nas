;----------------------------------------------------------------------------------------            
;int printf(FILE* fp, char* line, ...)
;return value - amount of printed symbols
;Uses unix SystemV call convention
;%d - 32-bit decimal signed number
;%c - char
;%s - string 
;%b - 32-bit binary 
;%o - 32-bit octal
;%x - 32-bit hexadecimal
;
;
;----------------------------------------------------------------------------------------            

default rel

extern get_descriptor

global myprintf

section .text

%macro multipush 1-* 
%rep %0 
          push %1 
%rotate 1 
%endrep 
%endmacro


%macro multipop 1-* 
%rep %0 
%rotate -1 
          pop %1 
%endrep 
%endmacro



BUFFER_SIZE equ 65536
%define PRINT_SIZE r11

;----------------------------------------------------------------------------------------            
;Destroylist:  
;all args in stack (Cdecl)
myprintf:   

            pop rax                             ;move returning address/ so stack has awesome structure
                                                ;like
            push r9                             ;-----------------------------
            push r8                             ;arguments transfered by stack
            push rcx                            ;-----------------------------
            push rdx                            ;aruments transfered by registers
                                                ;-----------------------------
            push rax                            ;returning address
            push rbp                            ;-----------------------------
            

            
            mov rbp, rsp                        

            multipush rbx, r12, r13, r14, r15


            push rsi
            call get_descriptor                 ;get int file_descriptor from FILE* by fileno(FILE* fp)
            pop rsi


                                                ;rsi contais line pointer

            mov r9, rax                         ;save file descriptor in r9
            lea rdi, [Print_buff]               ;save in rdi printf buffer


            mov r8, rbp                         ;save in r8 pointer on
            add r8, 16                          ;second argument after line

            xor PRINT_SIZE, PRINT_SIZE          ;length of print line

            cmp byte [rsi], 0x0                 ;check if line is empty
            je end_printf_while

;;-------------------

begin_printf_while:
            cmp byte [rsi], '%'                 ;check if it is time to write variable
            jne print_symbol
                inc rsi

                xor r10, r10                    ;clear register  

                mov r10b, [rsi]                 ;put in r10b x, where x is %'x'
                              
                call printf_switch              ;print variable, argument stores in r10b

                inc rsi                         
                jmp end_condition

print_symbol:

                movsb                           ;inc count register
                inc PRINT_SIZE
end_condition:
;
;
            cmp byte [rsi], 0x0                 ;check end of line
            jne begin_printf_while
end_printf_while:

            push PRINT_SIZE

            call drop_buffer                    

            pop rax

            multipop rbx, r12, r13, r14, r15

            pop rbp
            pop rcx
            add rsp, 32
            push rcx
            ret
;;----------------------------------------------------------------------------------------

drop_buffer:
            lea rsi, Print_buff 
            mov rax, 0x01      
            mov rdi, r9         
            mov rdx, PRINT_SIZE

            syscall
            ret
;
;;----------------------------------------------------------------------------------------
printf_switch:
            cmp r10b, '%'                   ; check if it is %%
            je percent

            sub r10b, 'b'                   ;calculate label address
            cmp r10b, 'x' - 'b'             ; max - min
            ja  default_switch              ;check is value ok
            lea rbx, [switch_table]               

            mov r10, [rbx + r10*8]          
            add r10, rbx

            jmp r10
switch_table:
            dq  binary          - switch_table
            dq  char            - switch_table
            dq  decimal         - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  octal           - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  string          - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  default_switch  - switch_table
            dq  hexadeciaml     - switch_table
decimal:
            
            multipush rax, rcx, rbx, rdx, r13, r14
            xor rax, rax
            
            mov eax, [r8]
            add r8, 8
            call print_decimal

            multipop rax, rcx, rbx, rdx, r13, r14

            jmp     end_switch
;/----------------------------------------------------------------------------            
char:
            push rax
            
            mov rax, [r8]
            add r8, 8
            stosb
            inc PRINT_SIZE
            
            pop rax

            jmp     end_switch
;/----------------------------------------------------------------------------            
string:
            push rsi

            mov rsi, [r8]
            add r8, 8
            call print_string

            pop rsi
            jmp     end_switch
;/----------------------------------------------------------------------------            
hexadeciaml:
            multipush rax, rcx, rbx, rdx, r14, r9

            mov cl, 4
            xor rax, rax

            mov eax, [r8]
            add r8, 8
            call print_2_pow_sys

            multipop rax, rcx, rbx, rdx, r14, r9
            jmp     end_switch
;/----------------------------------------------------------------------------            
binary:
            
            multipush rax, rcx, rbx, rdx, r14, r9

            mov cl, 1
            xor rax, rax
            
            mov eax, [r8]
            add r8, 8
            call print_2_pow_sys

            multipop rax, rcx, rbx, rdx, r14, r9
            
            jmp     end_switch
;/----------------------------------------------------------------------------            
octal:
            multipush rax, rcx, rbx, rdx, r14, r9

            mov cl, 3
            xor rax, rax
            
            mov eax, [r8]
            add r8, 8
            call print_2_pow_sys

            multipop rax, rcx, rbx, rdx, r14, r9
            jmp     end_switch
;/----------------------------------------------------------------------------            
percent:
            mov byte [rdi], '%'
            inc rdi
            inc PRINT_SIZE
            jmp     end_switch
;/----------------------------------------------------------------------------            

default_switch:
            push rsi

            lea rsi, Error_msg
            call print_string

            pop rsi
end_switch:

            ret
;;----------------------------------------------------------------------------------------
print_decimal:

;;Destroy list: rax, rcx, r14, rbx, rdx, r13
;;               
;;eax - register to print
            push rbp
            mov rbp, rsp

            mov r15, 1
            shl r15, 31
            and r15, rax

            cmp r15, 0
            je skip_not
                not eax
                inc eax
skip_not:
            xor rcx, rcx
            xor r14, r14

            mov rbx, 10

            lea r13, [Symbols]            

Calculate_10_loop:
                xor edx, edx                        ;divisions by 10
                div ebx

                mov r14b, [r13 + rdx]               ;put in r14b exact symbol
                push r14

                inc rcx

                cmp eax, 0                          ;check if this is the end 
            jne Calculate_10_loop

            cmp r15, 0
            je skip_minus
                mov al, '-'
                stosb
                inc PRINT_SIZE
                
skip_minus:

Add_in_buffer_loop:
                pop rax
                stosb
                inc PRINT_SIZE
            loop Add_in_buffer_loop                 ;drop in buffer all symbols loop
            pop rbp
            ret
;;----------------------------------------------------------------------------------------



print_2_pow_sys:
;-----------------------------------------------------------------------------
;;Destroy list: rax, rcx, rbx, rdx, r14, r9
;;               
;;eax - register to print
;;cl - bites per symbol
            push rbp
            mov rbp, rsp

            xor rdx, rdx
            xor r14, r14

            xor ebx, ebx
            inc ebx
            shl ebx, cl
            dec ebx

            xor ch, ch
            lea r9, [Symbols]

.loop:            
            mov edx, ebx
            and edx, eax            
            mov r14b, [r9 + rdx]           ;put in r14b exact symbol
            push r14                        

            inc ch                         ; inc count of symbols in outpput
            shr eax, cl

            cmp eax, 0                      
            jne .loop

.loop2:
            pop rax
            stosb                           ;svae in buffers symbols in right order
            dec ch
            inc PRINT_SIZE

            cmp ch, 0
            jne .loop2



            pop rbp
            ret
;----------------------------------------------------------------------------------------
;Destroy_list:
;rsi - string pointer
print_string:
            cmp byte [rsi], 0
            je .end
.begin_loop:
            movsb
            inc PRINT_SIZE

            cmp byte [rsi], 0
            jne .begin_loop
.end:
            ret
;----------------------------------------------------------------------------------------


section     .data


Symbols		db '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
Error_msg   db "(Wrong % specifier)",0


section     .bss
Print_buff resb BUFFER_SIZE 
End_print_buff:

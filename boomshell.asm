section .data
    prompt db "boomshell> ", 0
    prompt_len equ $ - prompt
    sh_path db "/bin/sh", 0
    sh_arg2 db "-c", 0

    env_term db "TERM=xterm-256color", 0

section .bss
    cmd_buf resb 256             

section .text
    global _start

_start:
.loop:
    ; prompt boomshell> 
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    mov ecx, prompt
    mov edx, prompt_len
    int 0x80

    
    mov eax, 3                  ; sys_read
    mov ebx, 0                  ; stdin
    mov ecx, cmd_buf
    mov edx, 255                
    int 0x80

    
    cmp eax, 1
    jle .loop                   

    mov byte [cmd_buf + eax - 1], 0

    ; create fork
    mov eax, 2                  ; sys_fork
    int 0x80
    
    cmp eax, 0
    je .child_process           
    js .loop                    ; loop when fork fails

    mov ebx, eax                
    mov eax, 7                  ; sys_waitpid
    xor ecx, ecx                ; status = NULL
    xor edx, edx                ; options = 0
    int 0x80
    jmp .loop                   

.child_process:
    xor eax, eax
    push eax                    
    mov eax, env_term
    push eax                    ; envp[0] = "TERM=xterm-256color"
    mov edx, esp                

    xor eax, eax
    push eax                    
    push cmd_buf                
    mov eax, sh_arg2
    push eax                    ; argv[1] = "-c"
    mov eax, sh_path
    push eax                    ; argv[0] = "/bin/sh"
    mov ecx, esp                
    
    mov ebx, sh_path            
    
    mov eax, 11                 ; sys_execve
    int 0x80

    ; kill child process if execve fails
    mov eax, 1                  ; sys_exit
    xor ebx, ebx
    int 0x80


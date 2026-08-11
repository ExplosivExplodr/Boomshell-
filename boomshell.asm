section .data
    prompt db "Bsh@ ", 0
    prompt_len equ $ - prompt
    
    bin_prefix db "/bin/", 0
    bin_prefix_len equ $ - bin_prefix - 1

    ; built in command strings for comparison
    cmd_cd db "cd", 0
    cmd_exit db "exit", 0

section .bss
    cmd_buf resb 256             ; input buffer for user commands
    path_buf resb 64             ; path buffer for "/bin/command"
    argv_space resd 10           ; array to store up to 10 argument pointers

section .text
    global _start

_start:
.loop:
    ; 1. Print Prompt
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    mov ecx, prompt
    mov edx, prompt_len
    int 0x80

    ; 2. Read User Input
    mov eax, 3                  ; sys_read
    mov ebx, 0                  ; stdin
    mov ecx, cmd_buf
    mov edx, 255                
    int 0x80

    cmp eax, 1                  ; if only return is pressed, loop back
    jle .loop                   

    ; replace newline character (\n) with null-terminator (0)
    mov byte [cmd_buf + eax - 1], 0

    ; tokenising input
    mov esi, cmd_buf            ; Source pointer
    mov edi, argv_space         ; Destination pointer for argv array
    xor ecx, ecx                ; Argument counter

    ; Save the pointer to the first argument
    mov [edi], esi
    add edi, 4
    inc ecx

.parse_loop:
    mov al, [esi]
    cmp al, 0
    je .parse_done              ; end of string reached
    
    cmp al, 32                  ; check if character is space (0x20)
    jne .next_char

    ; if space is found: set to null and save next address as next argument
    mov byte [esi], 0
    
    ; handle multiple consecutive spaces
    mov al, [esi + 1]
    cmp al, 32
    je .next_char
    cmp al, 0
    je .parse_done

    lea eax, [esi + 1]
    mov [edi], eax              ; save next argument pointer to argv
    add edi, 4
    inc ecx

.next_char:
    inc esi
    jmp .parse_loop

.parse_done:
    mov dword [edi], 0          ; terminate argv array with null 
; this is necessary

    ; Check for Built-in Commands 
    ;this must run in parent process, NO FORK because they are builtin
    mov esi, [argv_space]       ; Pointer to the first command string

    ; and for the exit command
    mov edi, cmd_exit
    call .strcmp
    cmp eax, 0
    je .handle_exit
;hihihiha
    ; cd command also did not work in the previous version so here is the fix
    mov edi, cmd_cd
    call .strcmp
    cmp eax, 0
    je .handle_cd

    ; forking external commands
    mov eax, 2                  ; sys_fork
    int 0x80
    
    cmp eax, 0
    je .child_process           
    js .loop                    ; loop back if fork fails

    ; PARENT PROCESS
    mov ebx, eax                ; ebx = child PID
    mov eax, 7                  ; sys_waitpid
    xor ecx, ecx                ; status = NULL
    xor edx, edx                ; options = 0
    xor esi, esi                ; rusage = NULL (Fixes EFAULT)
    int 0x80
    jmp .loop                   

.child_process:
    ; building command path ("/bin/" + command)
    mov esi, bin_prefix
    mov edi, path_buf
    
.copy_prefix:
    lodsb
    cmp al, 0
    je .copy_cmd
    stosb
    jmp .copy_prefix

.copy_cmd:
    mov esi, [argv_space]       ; get first argument string address
.copy_cmd_loop:
    lodsb
    stosb
    cmp al, 0
    jne .copy_cmd_loop

    ; 7. Execute via sys_execve
    mov ebx, path_buf           ; ebx = executable path 
				; for example "/bin/ls"
    mov ecx, argv_space         ; ecx = argv array pointer
    xor edx, edx                ; edx = envp (NULL)
    
    mov eax, 11                 ; s+ys_execve
    int 0x80

    ; if execve fails exit child process cleanly
    mov eax, 1                  ; sys_exit
    mov ebx, 127                ; command not found exit code
    int 0x80

; builtin headers
.handle_exit:
    mov eax, 1                  ; sys_exit
    xor ebx, ebx                ; exit status = 0
    int 0x80

.handle_cd:
    ; check if directory argument exists (argv[1])
    mov ebx, [argv_space + 4]   ; ebx = argv[1]
    cmp ebx, 0
    je .loop                    ; if no target directory specified, just loop back
    
    mov eax, 12                 ; sys_chdir (syscall 12)
    int 0x80                    ; execute change directory on parent process
    jmp .loop

; sting compare
; compares null-terminated strings in ESI and EDI
; returns EAX = 0 if equal non-zero otherwise
.strcmp:
    push esi
    push edi
.strcmp_loop:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .strcmp_diff
    cmp al, 0
    je .strcmp_equal
    inc esi
    inc edi
    jmp .strcmp_loop
.strcmp_diff:
    mov eax, 1
    jmp .strcmp_end
.strcmp_equal:
    xor eax, eax
.strcmp_end:
    pop edi
    pop esi
    ret

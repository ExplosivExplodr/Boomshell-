##      BOOMSHELL!      ##


This is a shell for linux.
written in linux x86 assembly (IA-32) 
its so small that you can fit it inside your cpu cache. 
To assemble it, make the installing script executable and execute: 
```Bash
chmod +x install.sh
# execute
./install.sh
```
its a really small script, so you can also just run the assembler and linker commands separately
```Bash
nasm -f elf32 boomshell.asm -o boomshell.o # Assemble
ld -m elf_i386 boomshell.o -o boomshell # Link
```

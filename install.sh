#/bin/bash
read -p "Continue? (Y/N): " confirm
[[ "$confirm" == [yY] || "$confirm" == [yY][eE][sS] ]] || exit 1

echo "assembling..."
nasm -f elf32 boomshell.asm -o boomshell.o && \
ld -m elf_i386 boomshell.o -o boomshell && \
echo "copying to /bin ..." && \
sudo cp boomshell /bin && \
echo "done"

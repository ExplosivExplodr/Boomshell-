echo "assembling..."
nasm -f elf32 boomshell.asm -o boomshell.o
ld -m elf_i386 boomshell.o -o boomshell

echo "copying to /bin ..."
sudo cp boomshell /bin
echo "done"

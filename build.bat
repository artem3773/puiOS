@echo off

cd scr
nasm -f bin boot.asm -o boot.bin
nasm -f bin os.asm -o os.bin
cd ..
move scr\os.bin bin\
move scr\boot.bin bin\

cd bin
copy /b boot.bin + os.bin os.img

pause
echo "  Compiling hello.asm"
rgbasm -o hello.o hello.asm
echo "  Linking hello.bin"
lua5.3 ../../linkhax.lua -b da00 -o hello.bin hello.o

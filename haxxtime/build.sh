echo "  Generating Symbol Definitions"
lua5.3 makesymbols.lua ../../pokeblue.sym > symbols.asm
echo "  Compiling main.asm"
rgbasm -o main.o main.asm
echo "  Linking"
lua5.3 ../linkhax.lua -b a000 -o exploit.bin main.o

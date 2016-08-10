echo "  Compiling ip.asm"
rgbasm -o ip.o ip.asm
echo "  Linking"
# we have an sram callguard, which is 20 bytes in size
# so we move our base back
lua5.3 ../linkhax.lua -b db29 -o ip.bin ip.o

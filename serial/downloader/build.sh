echo "  Compiling downloader.asm"
rgbasm -o downloader.o downloader.asm
echo "  Linking downloader.bin"
lua5.3 ../../linkhax.lua -b c5d6 -o downloader.bin downloader.o

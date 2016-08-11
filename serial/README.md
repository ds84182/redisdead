# serial

This directory contains code that allows sramhax, and potentially any other modifications, to be installed into the SRAM of a Pokemon Red/Blue cart. This is not tested on actual hardware, only BGB (that counts, right?).

### downloader (codename PGI:SPD [Pokemon Gen I Serial Program Downloader])

__downloader__ is, you guessed it, a program that downloads things. What things exactly? __downloader__ allows you to download code (gasp) over serial. It gets bootstrapped by a remote code execution exploit found by vaguilar [which can be found here](http://vaguilar.js.org/posts/1/). __downloader__ then downloads...

### sram_flash (codename PGI:ST [Pokemon Gen I Save Tool])

__sram_flash__ can dump and flash the entire SRAM through serial. This is used to install __sramhax__. And to glue this all together we use...

### serial.lua (codename MPHAOA [Mupen64 Plugin Hell All Over Again])

__serial.lua__ is a command line tool that communicated to bgb to do serial communications with the emulated host. It features an extensive (I guess) plugin system and is the heart of the entire thing. It sets up __downloader__ via RCE. It provides binaries to __downloader__. It even manages saving, recombining, and sending sram dumps to __sram_flash__. And via "powerful" abstractions the code can be repurposed to communicate to an Arduino to mess around with a REAL Pokemon Red/Blue Cart running on a REAL Gameboy!

### What about install.lua?

We don't talk about that piece of legacy rubbish :)

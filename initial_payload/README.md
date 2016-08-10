# initial_payload

This directory contains the initial payload for sramhax. It is responsible for switching SRAM banks to call into sramhax, since it lives in main ram. It also exports a function to allow sramhax to call functions that mess with SRAM banking without causing a crash when returning back to sramhax.

Currently the code has size constraints. Any modifications to this code may break something in bad ways.

local addr = ...
addr = tonumber(addr, 16)

print(string.format("%x", 0x25a3+(addr-0xd2f7)))

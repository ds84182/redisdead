BUILD = $(notdir $(shell pwd))
ASM = $(BUILD).asm
OBJECT = build/$(BUILD).o

-include CONFIG.mk

BASE_ADDR ?= da00

.PHONY: clean

default: $(BUILD).bin

$(BUILD).bin: build $(OBJECT)
# TODO: Find subdirectory with linkhax.lua
	@echo "$(OBJECT) -> $(BUILD).bin"
	@lua5.3 ../../linkhax.lua -b $(BASE_ADDR) -o $(BUILD).bin $(OBJECT)

build:
	@mkdir -p build

clean:
	@rm -rf build

build/%.o: source/%.asm
	@echo "$< -> $@"
	@cd source && rgbasm -o ../$@ $(subst source/,,$<)

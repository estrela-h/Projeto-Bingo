#==============================================================================
# Makefile - Bingo Eletrônico ATmega328P (v2 corrigida)
#==============================================================================
MCU      = atmega328p
F_CPU    = 16000000UL
SRC_ASM  = bingo_main.asm
TARGET   = bingo
ELF      = $(TARGET).elf
HEX      = $(TARGET).hex
LST      = $(TARGET).lst

CC       = avr-gcc
OBJCOPY  = avr-objcopy
OBJDUMP  = avr-objdump
SIZE     = avr-size
AVRDUDE  = avrdude

ASMFLAGS = -mmcu=$(MCU) -DF_CPU=$(F_CPU) -x assembler-with-cpp -Wall

PROGRAMMER = arduino
PORT       ?= /dev/ttyUSB0
BAUD       = 115200

.PHONY: all clean flash size disasm

all: $(HEX) size

$(ELF): $(SRC_ASM)
	$(CC) $(ASMFLAGS) -o $@ $<

$(HEX): $(ELF)
	$(OBJCOPY) -O ihex -R .eeprom $< $@
	@echo ""
	@echo ">>> Arquivo gerado com sucesso: $(HEX)"

size: $(ELF)
	@echo ""
	@$(SIZE) --format=avr --mcu=$(MCU) $(ELF)

flash: $(HEX)
	$(AVRDUDE) -c $(PROGRAMMER) -p $(MCU) -P $(PORT) -b $(BAUD) -U flash:w:$<:i

disasm: $(ELF)
	$(OBJDUMP) -h -S $< > $(LST)

clean:
	rm -f $(ELF) $(HEX) $(LST)


#RISCVGNU ?= riscv32-unknown-elf

# requires $(RISCVGNU)-ld option -b elf32-littleriscv
RISCVGNU ?= riscv64-unknown-elf

AOPS = -march=rv32imac -mabi=ilp32 -g
COPS = -march=rv32imac -mabi=ilp32 -g -Wall -O2 -nostdlib -nostartfiles -ffreestanding
#AOPS = -mabi=ilp32
#COPS = -mabi=ilp32 -Wall -O2 -nostdlib -nostartfiles -ffreestanding

OPENOCD_WIN = openocd
OPENOCD_LIN = sudo openocd
OPENOCD = $(OPENOCD_WIN)

DELCMD_WIN = del
DELCMD_LIN = rm -f
DELCMD = $(DELCMD_WIN)

PROGRAM := main

all :

#
# Program Definition
#

clean :
	$(DELCMD) start.o
	$(DELCMD) prci.o
	$(DELCMD) $(PROGRAM).o
	$(DELCMD) $(PROGRAM)-ram.elf
	$(DELCMD) $(PROGRAM)-ram.bin
	$(DELCMD) $(PROGRAM)-ram.lst
	$(DELCMD) $(PROGRAM)-ram.hex
	$(DELCMD) $(PROGRAM)-ram.map
	$(DELCMD) $(PROGRAM)-rom.elf
	$(DELCMD) $(PROGRAM)-rom.bin
	$(DELCMD) $(PROGRAM)-rom.lst
	$(DELCMD) $(PROGRAM)-rom.hex
	$(DELCMD) $(PROGRAM)-rom.map

start.o : start.s
	$(RISCVGNU)-as $(AOPS) start.s -o start.o

prci.o : prci.s
	$(RISCVGNU)-as $(AOPS) prci.s -o prci.o


$(PROGRAM).o : $(PROGRAM).c
	$(RISCVGNU)-gcc $(COPS) -c $(PROGRAM).c -o $(PROGRAM).o

#
# RAM link and load
#

ram : fe310-g002-ram.lds start.o prci.o $(PROGRAM).o
	$(RISCVGNU)-ld start.o prci.o $(PROGRAM).o -T fe310-g002-ram.lds -o $(PROGRAM)-ram.elf -Map $(PROGRAM)-ram.map -b elf32-littleriscv
	$(RISCVGNU)-objdump -D $(PROGRAM)-ram.elf > $(PROGRAM)-ram.lst
	$(RISCVGNU)-objcopy $(PROGRAM)-ram.elf -O ihex $(PROGRAM)-ram.hex
	$(RISCVGNU)-objcopy $(PROGRAM)-ram.elf -O binary $(PROGRAM)-ram.bin

ifeq (LOAD, $(tgt))
#	@openocd -f interface/ftdi/olimex-arm-usb-tiny-h.cfg -f fe310-g002.cfg -c init -c "asic_ram_load $(PROGRAM)" -c shutdown -c exit
#	@openocd                                             -f fe310-g002.cfg -c init -c "asic_ram_load $(PROGRAM)"
	@openocd                                             -f unbrick.cfg -c init
	@echo "target RAM programmed"
else
	@echo "target not changed"
endif

#
# ROM link and load
#

rom : fe310-g002-rom.lds start.o prci.o $(PROGRAM).o
	$(RISCVGNU)-ld start.o prci.o $(PROGRAM).o -T fe310-g002-rom.lds -o $(PROGRAM)-rom.elf -Map $(PROGRAM)-rom.map -b elf32-littleriscv
	$(RISCVGNU)-objdump -D $(PROGRAM)-rom.elf > $(PROGRAM)-rom.lst
	$(RISCVGNU)-objcopy $(PROGRAM)-rom.elf -O ihex $(PROGRAM)-rom.hex
	$(RISCVGNU)-objcopy $(PROGRAM)-rom.elf -O binary $(PROGRAM)-rom.bin

ifeq (LOAD, $(tgt))
#	$(eval SECSZ=$(shell echo "ibase=16; 1000" | bc))
#	$(eval LEN=$(shell <${PROGRAM}-rom.bin wc -c))
#	$(eval ENDSEC=$(shell echo "(${LEN}/${SECSZ})+((${LEN}-(${LEN}/${SECSZ})*${SECSZ})>0)-1" | bc))

#	@echo "secsz=${SECSZ} len=${LEN} endsec=${ENDSEC}"

#	@openocd -f interface/ftdi/olimex-arm-usb-tiny-h.cfg -f fe310-g002.cfg -c init -c "asic_rom_load $(PROGRAM)" -c shutdown -c exit
#	@openocd                                             -f fe310-g002.cfg -c init -c "asic_rom_load $(PROGRAM)" -c shutdown -c exit
	@openocd                                             -f unbrick.cfg -c init
	@echo "target ROM programmed"
else
	@echo "target not changed"
endif


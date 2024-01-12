CC = riscv64-unknown-elf-gcc
AS = riscv64-unknown-elf-gcc
LD = riscv64-unknown-elf-gcc
OBJDUMP = riscv64-unknown-elf-objdump
OBJCOPY = riscv64-unknown-elf-objcopy
SIZE = riscv64-unknown-elf-size

CFLAGS = -c -Wall -std=c11 -march=rv32im -mabi=ilp32 -O2 -ffunction-sections -fdata-sections -Ibarebones -I. -DPERFORMANCE_RUN=1 -DITERATIONS=6000
# CFLAGS = -c -Wall -std=c11 -march=rv32im -mabi=ilp32 -O2 -ffunction-sections -fdata-sections -Ibarebones -I. -DVALIDATION_RUN=1 -DITERATIONS=1
ASFLAGS = -c -Wall -march=rv32im -mabi=ilp32
LDFLAGS = -nostartfiles -T link.ld -march=rv32im -mabi=ilp32 --specs=nano.specs -Wl,-Map,$(TARGET:%.elf=%.map) -Wl,--gc-sections
SECTRM = -R.comment -R.riscv.attributes -R.debug_loc -R.debug_str -R.debug_info -R.debug_abbrev -R.debug_line

SOURCES = init.S \
	uart.c \
	core_main.c \
	core_list_join.c \
	core_matrix.c \
	core_state.c \
	core_util.c \
	barebones/core_portme.c \
	barebones/ee_printf.c
OBJECTS = $(patsubst %.S,%.o,$(patsubst %c,%o,$(SOURCES)))
TARGET = core_main.elf
ROMFILE = rom.hex

all: clean hex

hex: $(SOURCES) $(TARGET)
	$(OBJDUMP) -D $(TARGET) > $(TARGET:%.elf=%.lst)
	${OBJCOPY} $(SECTRM) -O verilog --verilog-data-width=4 --reverse-bytes=4 $(TARGET) $(TARGET:%.elf=%.hex)
	python conv.py $(TARGET:%.elf=%.hex) $(ROMFILE)
	$(SIZE) $(TARGET)

$(TARGET): $(OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $(OBJECTS)

.S.o:
	$(AS) $(ASFLAGS) -o $@ $<

.c.o:
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)


# STM32H5x Standalone Makefile (no STM32CubeIDE dependencies)

SRC_DIR := Src
STARTUP_DIR := Startup
BUILD_DIR := build
INCLUDE_DIR := Inc
LINKER_SCRIPT := linker/STM32H563ZITX_FLASH.ld

SRCS := $(wildcard $(SRC_DIR)/*.c)
STARTUP_SRCS := $(wildcard $(STARTUP_DIR)/*.s)
OBJS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SRCS)) \
		$(patsubst $(STARTUP_DIR)/%.s,$(BUILD_DIR)/%.o,$(STARTUP_SRCS))

TARGET := STM32H5x
ELF := $(BUILD_DIR)/$(TARGET).elf
MAP := $(BUILD_DIR)/$(TARGET).map
LIST := $(BUILD_DIR)/$(TARGET).list

CFLAGS := -mcpu=cortex-m33 -std=gnu11 -DSTM32H563ZITx -DSTM32 -DSTM32H5 -DNUCLEO_H563ZI -I$(INCLUDE_DIR) -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -mthumb -mfpu=fpv5-sp-d16 -mfloat-abi=hard
LDFLAGS := -T$(LINKER_SCRIPT) --specs=nosys.specs -Wl,-Map=$(MAP) -Wl,--gc-sections -static --specs=nano.specs -Wl,--start-group -lc -lm -Wl,--end-group
ASFLAGS := -mcpu=cortex-m33 -mthumb -mfpu=fpv5-sp-d16 -mfloat-abi=hard -x assembler-with-cpp

all: $(ELF) $(LIST)

$(ELF): $(OBJS) $(LINKER_SCRIPT)
	@mkdir -p $(BUILD_DIR)
	arm-none-eabi-gcc -o $@ $(OBJS) $(CFLAGS) $(LDFLAGS)
	@echo 'Finished building target: $@'

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	arm-none-eabi-gcc $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(STARTUP_DIR)/%.s | $(BUILD_DIR)
	arm-none-eabi-gcc $(ASFLAGS) -c $< -o $@

$(LIST): $(ELF)
	arm-none-eabi-objdump -h -S $< > $@
	@echo 'Finished building: $@'

size: $(ELF)
	arm-none-eabi-size $<

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)
	@echo 'Cleaned build artifacts.'

.PHONY: all clean size
flash:
	tools/openocd/bin/openocd -f tools/openocd/openocd.cfg -c "program build/STM32H5x.elf verify reset exit"

debug:
	tools/openocd/bin/openocd -f tools/openocd/openocd.cfg

gdb:
	gdb-multiarch -x tools/gdb/gdbinit_stm32h5 build/STM32H5x.elf

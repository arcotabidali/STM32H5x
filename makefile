
# STM32H5x Standalone Makefile (no STM32CubeIDE dependencies)

SRC_DIR := Src
HAL_DRIVER_SRC_DIR := Drivers/STM32H5xx_HAL_Driver/Src
HAL_DRIVER_INC_DIR := Drivers/STM32H5xx_HAL_Driver/Inc
STARTUP_DIR := Startup
BUILD_DIR := build
INCLUDE_DIR := Inc
CMSIS_DEVICE_INC_DIR := Drivers/CMSIS/Device/ST/STM32H5xx/Include
LINKER_SCRIPT := linker/STM32H563ZITX_FLASH.ld

# Source and include directories
CMSIS_CORE_INC_DIR := Drivers/CMSIS/Include
SRC_DIRS := $(SRC_DIR) $(HAL_DRIVER_SRC_DIR)
INCLUDE_DIRS := $(INCLUDE_DIR) $(HAL_DRIVER_INC_DIR) $(CMSIS_DEVICE_INC_DIR) $(CMSIS_CORE_INC_DIR)

# Source and object files
SRCS := $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.c))
STARTUP_SRCS := $(wildcard $(STARTUP_DIR)/*.s)
OBJS := $(foreach dir,$(SRC_DIRS),$(patsubst $(dir)/%.c,$(BUILD_DIR)/%.o,$(wildcard $(dir)/*.c))) \
	$(patsubst $(STARTUP_DIR)/%.s,$(BUILD_DIR)/%.o,$(STARTUP_SRCS))

TARGET := STM32H5x
ELF := $(BUILD_DIR)/$(TARGET).elf
MAP := $(BUILD_DIR)/$(TARGET).map
LIST := $(BUILD_DIR)/$(TARGET).list

# Debug toggle: set DEBUG=1 when running make to build a debug-friendly binary
ifeq ($(DEBUG),1)
CFLAGS := -mcpu=cortex-m33 -std=gnu11 -DSTM32H563xx -DSTM32 -DSTM32H5 -DNUCLEO_H563ZI $(addprefix -I,$(INCLUDE_DIRS)) -g3 -Og -fno-omit-frame-pointer -fno-inline -ffunction-sections -fdata-sections -Wall -fstack-usage -mthumb -mfpu=fpv5-sp-d16 -mfloat-abi=hard -DDEBUG
else
CFLAGS := -mcpu=cortex-m33 -std=gnu11 -DSTM32H563xx -DSTM32 -DSTM32H5 -DNUCLEO_H563ZI $(addprefix -I,$(INCLUDE_DIRS)) -Os -ffunction-sections -fdata-sections -Wall -fstack-usage -mthumb -mfpu=fpv5-sp-d16 -mfloat-abi=hard
endif
# For semi-hosting
# LDFLAGS := -T$(LINKER_SCRIPT) -Wl,-Map=$(MAP) -Wl,--gc-sections -static --specs=rdimon.specs -lc -lrdimon -Wl,--start-group -lc -lm -Wl,--end-group
# Comment above and uncomment below for no semi-hosting and move syscall.c from no-build to Src
# then remove initialise_monitor_handles() from main.c
LDFLAGS := -T$(LINKER_SCRIPT) --specs=nosys.specs -Wl,-Map=$(MAP) -Wl,--gc-sections -static --specs=nano.specs -Wl,--start-group -lc -lm -Wl,--end-group
ASFLAGS := -mcpu=cortex-m33 -mthumb -mfpu=fpv5-sp-d16 -mfloat-abi=hard -x assembler-with-cpp

all: $(ELF) $(LIST)

$(ELF): $(OBJS) $(LINKER_SCRIPT)
	@mkdir -p $(BUILD_DIR)
	arm-none-eabi-gcc -o $@ $(OBJS) $(CFLAGS) $(LDFLAGS)
	@echo 'Finished building target: $@'


# Pattern rule for Src
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	arm-none-eabi-gcc $(CFLAGS) -c $< -o $@

# Pattern rule for HAL driver sources
$(BUILD_DIR)/%.o: $(HAL_DRIVER_SRC_DIR)/%.c | $(BUILD_DIR)
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

# Build a debug-friendly binary (uses DEBUG=1)
.PHONY: build-debug
build-debug:
	@echo "Building debug binary..."
	$(MAKE) all DEBUG=1

# Start OpenOCD in background and record PID to .openocd.pid
.PHONY: debug-start
debug-start:
	@echo "Starting OpenOCD (background)..."
	tools/openocd/bin/openocd -f tools/openocd/openocd.cfg & echo $$! > .openocd.pid
	@sleep 0.2
	@echo "OpenOCD started (pid `cat .openocd.pid` )"

# Stop OpenOCD started by debug-start
.PHONY: debug-stop
debug-stop:
	@if [ -f .openocd.pid ]; then \
		kill `cat .openocd.pid` || true; \
		rm -f .openocd.pid; \
		echo "Stopped OpenOCD"; \
	else \
		echo "No OpenOCD pid file (.openocd.pid) found"; \
	fi

# Build debug binary, start OpenOCD, then run gdb; when gdb exits, stop OpenOCD
.PHONY: debug-gdb
debug-gdb: build-debug debug-start
	gdb-multiarch -x tools/gdb/gdbinit_stm32 build/STM32H5x.elf ; $(MAKE) debug-stop

# Convenience alias: build debug, flash it and start gdb session
.PHONY: debug-all
debug-all: build-debug flash debug-gdb

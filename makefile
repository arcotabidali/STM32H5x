

flash:
	tools/openocd/bin/openocd -f tools/openocd/openocd.cfg -c "program build/Lab0_HelloWorld.elf verify reset exit"
debug:
	tools/openocd/bin/openocd -f tools/openocd/openocd.cfg
gdb:
	gdb-multiarch -x tools/gdb/gdbinit_stm32h5 build/Lab0_HelloWorld.elf


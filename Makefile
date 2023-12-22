
PROGRAM=f100l
SOURCE= \
  src/$(PROGRAM).v \
  src/block_ram.v \
  src/eeprom.v \
  src/memory_bus.v \
  src/peripherals.v \
  src/ram.v \
  src/mandelbrot.v \
  src/rom.v \
  src/servo_control.v \
  src/spi.v

default:
	yosys -q -p "synth_ice40 -top $(PROGRAM) -json $(PROGRAM).json" $(SOURCE)
	nextpnr-ice40 -r --hx8k --json $(PROGRAM).json --package cb132 --asc $(PROGRAM).asc --opt-timing --pcf icefun.pcf
	icepack $(PROGRAM).asc $(PROGRAM).bin

program:
	iceFUNprog $(PROGRAM).bin

blink:
	naken_asm -l -type bin -o blink.bin test/blink.asm
	python3 tools/lst2verilog.py blink.lst > src/rom.v

rom_0:
	naken_asm -l -type bin -o p_mode.bin test/p_mode.asm
	python3 tools/lst2verilog.py p_mode.lst > src/rom.v

rom_1:
	naken_asm -l -type bin -o load_byte.bin test/load_byte.asm
	python3 tools/lst2verilog.py load_byte.lst > src/rom.v

rom_2:
	naken_asm -l -type bin -o branch.bin test/branch.asm
	python3 tools/lst2verilog.py branch.lst > src/rom.v

rom_3:
	naken_asm -l -type bin -o compare.bin test/compare.asm
	python3 tools/lst2verilog.py compare.lst > src/rom.v

rom_4:
	naken_asm -l -type bin -o dec_jmp.bin test/dec_jmp.asm
	python3 tools/lst2verilog.py dec_jmp.lst > src/rom.v

rom_5:
	naken_asm -l -type bin -o rotate.bin test/rotate.asm
	python3 tools/lst2verilog.py rotate.lst > src/rom.v

rom_6:
	naken_asm -l -type bin -o switch.bin test/switch.asm
	python3 tools/lst2verilog.py switch.lst > src/rom.v

rom_7:
	naken_asm -l -type bin -o shift_d.bin test/shift_d.asm
	python3 tools/lst2verilog.py shift_d.lst > src/rom.v

rom_8:
	naken_asm -l -type bin -o call_ret.bin test/call_ret.asm
	python3 tools/lst2verilog.py call_ret.lst > src/rom.v

play_song:
	naken_asm -l -type bin -o play_song.bin test/play_song.asm
	#python3 tools/lst2verilog.py play_song.lst > src/rom.v

lcd:
	naken_asm -l -type bin -o lcd.bin test/lcd.asm
	python3 tools/lst2verilog.py lcd.lst > src/rom.v

spi:
	naken_asm -l -type bin -o spi.bin test/spi.asm
	python3 tools/lst2verilog.py spi.lst > src/rom.v

clean:
	@rm -f $(PROGRAM).bin $(PROGRAM).json $(PROGRAM).asc *.lst *.bin
	@echo "Clean!"


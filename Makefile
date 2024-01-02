
PROGRAM=f100l
SOURCE= \
  src/$(PROGRAM).v \
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
	naken_asm -l -type bin -o rom.bin test/blink.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

servo:
	naken_asm -l -type bin -o rom.bin -I test test/servo.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

rom_0:
	naken_asm -l -type bin -o rom.bin test/p_mode.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

rom_1:
	naken_asm -l -type bin -o rom.bin test/load_byte.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

rom_2:
	naken_asm -l -type bin -o rom.bin test/branch.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

rom_3:
	naken_asm -l -type bin -o rom.bin test/compare.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

rom_4:
	naken_asm -l -type bin -o rom.bin test/dec_jmp.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

rom_5:
	naken_asm -l -type bin -o rom.bin test/rotate.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

rom_6:
	naken_asm -l -type bin -o rom.bin test/switch.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

rom_7:
	naken_asm -l -type bin -o rom.bin test/shift_d.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

rom_8:
	naken_asm -l -type bin -o rom.bin test/call_ret.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

play_song:
	naken_asm -l -type bin -o rom.bin test/play_song.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

lcd:
	naken_asm -l -type bin -o rom.bin test/lcd.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

spi:
	naken_asm -l -type bin -o rom.bin test/spi.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

clean:
	@rm -f $(PROGRAM).bin $(PROGRAM).json $(PROGRAM).asc *.lst *.bin
	@echo "Clean!"


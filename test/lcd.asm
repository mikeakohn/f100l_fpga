.f100_l

.org 0x2000

;; Registers.
SPI_TX     equ 0x4001
SPI_RX     equ 0x4002
SPI_CTL    equ 0x4003
PORT0      equ 0x4008
SOUND      equ 0x4009
SPI_IO     equ 0x400a
;SPI_IO_0     equ 0x400b
;SPI_IO_1     equ 0x400c
;SPI_IO_2     equ 0x400d

;; Bits in SPI_CTL.
SPI_BUSY   equ 0
SPI_START  equ 1

;; Bits in SPI_IO.
LCD_RES    equ 0
LCD_DC     equ 1
LCD_CS     equ 2

;; Bits in PORT0
LED0       equ 0

COMMAND_DISPLAY_OFF     equ 0xae
COMMAND_SET_REMAP       equ 0xa0
COMMAND_START_LINE      equ 0xa1
COMMAND_DISPLAY_OFFSET  equ 0xa2
COMMAND_NORMAL_DISPLAY  equ 0xa4
COMMAND_SET_MULTIPLEX   equ 0xa8
COMMAND_SET_MASTER      equ 0xad
COMMAND_POWER_MODE      equ 0xb0
COMMAND_PRECHARGE       equ 0xb1
COMMAND_CLOCKDIV        equ 0xb3
COMMAND_PRECHARGE_A     equ 0x8a
COMMAND_PRECHARGE_B     equ 0x8b
COMMAND_PRECHARGE_C     equ 0x8c
COMMAND_PRECHARGE_LEVEL equ 0xbb
COMMAND_VCOMH           equ 0xbe
COMMAND_MASTER_CURRENT  equ 0x87
COMMAND_CONTRASTA       equ 0x81
COMMAND_CONTRASTB       equ 0x82
COMMAND_CONTRASTC       equ 0x83
COMMAND_DISPLAY_ON      equ 0xaf

.macro send_command(a)
  lda #a
  cal lcd_send_cmd
.endm

start:
  ;; Setup stack (lsp) to point to start at 0x100.
  lda #0xff
  sto 0
  ;; Clear LED.
  lda #0
  sto PORT0

main:
  cal lcd_init
  cal lcd_clear
  cal lcd_clear_2
  cal mandelbrot
while_1:
  cal delay
  cal toggle_led

  jmp while_1

lcd_init:
  lda #(1 << LCD_CS)
  sto SPI_IO
  cal delay
  set #LCD_RES, SPI_IO

  send_command(COMMAND_DISPLAY_OFF)
  send_command(COMMAND_SET_REMAP)
  send_command(0x72)
  send_command(COMMAND_START_LINE)
  send_command(0x00)
  send_command(COMMAND_DISPLAY_OFFSET)
  send_command(0x00)
  send_command(COMMAND_NORMAL_DISPLAY)
  send_command(COMMAND_SET_MULTIPLEX)
  send_command(0x3f)
  send_command(COMMAND_SET_MASTER)
  send_command(0x8e)
  send_command(COMMAND_POWER_MODE)
  send_command(COMMAND_PRECHARGE)
  send_command(0x31)
  send_command(COMMAND_CLOCKDIV)
  send_command(0xf0)
  send_command(COMMAND_PRECHARGE_A)
  send_command(0x64)
  send_command(COMMAND_PRECHARGE_B)
  send_command(0x78)
  send_command(COMMAND_PRECHARGE_C)
  send_command(0x64)
  send_command(COMMAND_PRECHARGE_LEVEL)
  send_command(0x3a)
  send_command(COMMAND_VCOMH)
  send_command(0x3e)
  send_command(COMMAND_MASTER_CURRENT)
  send_command(0x06)
  send_command(COMMAND_CONTRASTA)
  send_command(0x91)
  send_command(COMMAND_CONTRASTB)
  send_command(0x50)
  send_command(COMMAND_CONTRASTC)
  send_command(0x7d)
  send_command(COMMAND_DISPLAY_ON)
  rtn

lcd_clear:
  lda #0x10000 - (96 * 64)
  sto 2
lcd_clear_loop:
  lda #0xff
  cal lcd_send_data
  lda #0x0f
  cal lcd_send_data
  icz 2, lcd_clear_loop
  rtn

lcd_clear_2:
  lda #0x10000 - (96 * 64)
  sto 2
lcd_clear_loop_2:
  lda #0xf0
  cal lcd_send_data
  lda #0x0f
  cal lcd_send_data
  icz 2, lcd_clear_loop_2
  rtn

;; uint32_t multiply(int16_t, int16_t);
;; Address 6: input 0.
;; Address 7: input 1.
;; Address 8: output (LSB).
;; Address 9: output (MSB).
;; Address 10: counter.
;; Address 11: an MSB for input 0 (starts as 0).
multiply:
  ; Set output to 0.
  lda #0
  sto 8
  sto 9
  ; Set temporary LSB to 0.
  sto 11
  ; Set counter to 16.
  lda #0x10000 - 16
  sto 10
multiply_repeat:
  jbc #0, 7, multiply_ignore_bit
  clrm
  lda 6
  ads 8
  setm
  lda 11
  ads 9
multiply_ignore_bit:
  srl #1, 7
  clrm
  lda 6
  ads 6
  setm
  lda 11
  ads 11
  icz 10, multiply_repeat
  rtn

;; Address 8: output (LSB).
;; Address 9: output (MSB).
shift_right_10:
  srl #10, 8
  lda 9
  srl #10, 9
  and #0x3ff
  sll #6, A
  ads 8
  rtn

curr_x equ 20
curr_y equ 21
curr_r equ 22
curr_i equ 23
color  equ 24
zr     equ 25
zi     equ 26
zr2    equ 27
zi2    equ 28
tr     equ 29

mandelbrot:
  ;; final int DEC_PLACE = 10;
  ;; final int r0 = (-2 << DEC_PLACE);
  ;; final int i0 = (-1 << DEC_PLACE);
  ;; final int r1 = (1 << DEC_PLACE);
  ;; final int i1 = (1 << DEC_PLACE);
  ;; final int dx = (r1 - r0) / 96; (0x0020)
  ;; final int dy = (i1 - i0) / 64; (0x0020)

  ;; for (y = 0; y < 64; y++)
  lda #0x10000 - 64
  sto curr_y
  ;; int i = -1 << 10;
  lda #0xfc00
  sto curr_i
mandelbrot_for_y:
  ;; for (x = 0; y < 96; x++)
  lda #0x10000 - 96
  sto curr_x
  ;; int r = -2 << 10;
  lda #0xf800
  sto curr_r
mandelbrot_for_x:
  ;; zr = r;
  ;; zi = i;
  lda curr_r
  sto zr
  lda curr_i
  sto zi

  ;; for (int count = 0; count < 15; count++)
  lda #0x10000 - 15
  sto color
mandelbrot_for_count:
  ;; zr2 = (zr * zr) >> DEC_PLACE;
  lda zr
  sto 6
  sto 7
  cal multiply
  cal shift_right_10
  lda 8
  sto zr2

  ;; zi2 = (zi * zi) >> DEC_PLACE;
  lda zi
  sto 6
  sto 7
  cal multiply
  cal shift_right_10
  lda 8
  sto zi2

  ;; if (zr2 + zi2 > (4 << DEC_PLACE)) { break; }
  ;; cmp does: 4 - (zr2 + zi2).. if it's negative it's bigger than 4.
  lda zi2
  add zr2
  cmp #(4 << 10)
  jn mandelbrot_stop

  ;; tr = zr2 - zi2;
  lda zi2
  sub zr2
  sto tr

  ;; ti = ((zr * zi) >> DEC_PLACE) << 1;
  lda zr
  sto 6
  lda zi
  sto 7
  cal multiply
  cal shift_right_10
  sll #1, 8

  ;; zr = tr + curr_r;
  lda tr
  add curr_r
  sto zr

  ;; zi = ti + curr_i;
  lda 8
  add curr_i
  sto zi

  icz color, mandelbrot_for_count
mandelbrot_stop:

  lda color
  add #15
  add #colors
  sto color
  lda [color]
  srl #8, A
  cal lcd_send_data
  lda [color]
  and #0xff
  cal lcd_send_data

  ;; r += dx;
  lda #0x0020
  ads curr_r
  icz curr_x, mandelbrot_for_x

  ;; i += dy;
  lda #0x0020
  ads curr_i
  icz curr_y, mandelbrot_for_y
  rtn

;; lcd_send_cmd(A)
lcd_send_cmd:
  set #LED0,   PORT0
  clr #LCD_DC, SPI_IO
  clr #LCD_CS, SPI_IO

  sto SPI_TX

  set #SPI_START, SPI_CTL
lcd_send_cmd_wait:
  lda SPI_CTL
  cmp #(1 << SPI_BUSY)
  jz lcd_send_cmd_wait

  set #LCD_CS, SPI_IO
  rtn

;; lcd_send_data(A)
lcd_send_data:
  set #LED0,   PORT0
  set #LCD_DC, SPI_IO
  clr #LCD_CS, SPI_IO

  sto SPI_TX

  set #SPI_START, SPI_CTL
lcd_send_data_wait:
  lda SPI_CTL
  cmp #(1 << SPI_BUSY)
  jz lcd_send_data_wait
  set #LCD_CS, SPI_IO
  rtn

delay:
  lda #0
  sto 10
delay_loop:
  nop
  icz 10, delay_loop
  rtn

toggle_led:
  lda 3
  neq #1
  sto 3
  sto PORT0
  rtn

colors:
  dc16 0x0000
  dc16 0x000c
  dc16 0x0013
  dc16 0x0015
  dc16 0x0195
  dc16 0x0335
  dc16 0x04d5
  dc16 0x34c0
  dc16 0x64c0
  dc16 0x9cc0
  dc16 0x6320
  dc16 0xa980
  dc16 0xaaa0
  dc16 0xcaa0
  dc16 0xe980
  dc16 0xf800


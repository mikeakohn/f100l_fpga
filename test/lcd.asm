.f100_l

.org 0x2000

;; Registers.
SPI_TX     equ 0x6001
SPI_RX     equ 0x6002
SPI_CTL    equ 0x6003
PORT0      equ 0x6008
SPI_IO     equ 0x600a

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
  lda #0
  sto PORT0
  cal lcd_init
main:
  cal lcd_clear
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
  lda #0x10000 - (96 * 32)
  sto 2
lcd_clear_loop:
  lda #15
  cal lcd_send_data
  lda #0
  cal lcd_send_data
  icz 2, lcd_clear_loop
  rtn

;; lcd_send_cmd(A)
lcd_send_cmd:
  set #LED0,   PORT0
  clr #LCD_DC, SPI_IO
  clr #LCD_CS, SPI_IO

  sto SPI_TX
  set #SPI_START, SPI_CTL
  clrm
lcd_send_cmd_wait:
  lda SPI_CTL
  cmp #1
  jnz lcd_send_cmd_wait

  set #LCD_CS, SPI_IO
  rtn

;; lcd_send_data(A)
lcd_send_data:
  set #LED0,   PORT0
  set #LCD_DC, SPI_IO
  clr #LCD_CS, SPI_IO

  sto SPI_TX
  set #SPI_START, SPI_CTL
  clrm
lcd_send_data_wait:
  lda SPI_CTL
  cmp #1
  jnz lcd_send_cmd_wait

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
  sto 0x4008
  rtn


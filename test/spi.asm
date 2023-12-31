.f100_l
  
.org 0x2000
  
;; Registers.
SPI_TX     equ 0x4001
SPI_RX     equ 0x4002
SPI_CTL    equ 0x4003
PORT0      equ 0x4008
SOUND      equ 0x4009
SPI_IO     equ 0x400a

;; Bits in SPI_CTL.
SPI_BUSY   equ 0
SPI_START  equ 1

;; Bits in SPI_IO.
LCD_RES    equ 0
LCD_DC     equ 1
LCD_CS     equ 2

;; Bits in PORT0
LED0       equ 0

start:
  ;; Setup stack (lsp) to point to start at 0x100.
  lda #0xff
  sto 0
  ;; Clear LED.
  lda #0
  sto PORT0

main:
  lda #(1 << LCD_CS)
  sto SPI_IO
  cal delay
  set #LCD_RES, SPI_IO

  lda #0x51
  cal lcd_send_data

  ;; Set LED.
  lda #1
  sto PORT0

while_1:
  jmp while_1

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


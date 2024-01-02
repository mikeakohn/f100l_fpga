.f100_l
  
.org 0x2000

.include "registers.inc"

;; Bits in PORT1.
LCD_RES    equ 0
LCD_DC     equ 1
LCD_CS     equ 2
SPI1_CS    equ 3

;; Bits in PORT0
LED0       equ 0

;; Acclerometer regsiters.
VALUE_X    equ 0x0200
VALUE_Y    equ 0x0201
VALUE_Z    equ 0x0202

start:
  ;; Setup stack (lsp) to point to start at 0x100.
  lda #0xff
  sto 0
  ;; Clear LED.
  lda #0
  sto PORT0

  lda #(1 << SPI1_CS)
  sto PORT1

main:
  ;cal read_x
  ;cal read_y
  ;cal read_z

  ;; Rotate servo to full 0.
  lda #1
  sto PORT0
  lda #12000
  sto SERVO_0
  cal delay
  cal delay
  cal delay

  ;; Rotate servo to full 1.
  lda #0
  sto PORT0
  lda #24000
  sto SERVO_0
  cal delay
  cal delay
  cal delay
  jmp main

while_1:
  jmp while_1

read_x:
  clr #SPI1_CS, PORT1
  lda #0x0b
  cal spi_send_data
  lda #0x00
  cal spi_send_data
  lda #0x00
  cal spi_send_data
  set #SPI1_CS, PORT1
  rtn

;; spi_send_data(A) -> A
spi_send_data:
  sto SPI1_TX
  ;set #SPI_START, SPI1_CTL
  ;lda #(1 << SPI_START)
  lda #0xe2
  sto SPI1_CTL
spi_send_data_wait:
  lda SPI1_CTL
  cmp #(1 << SPI_BUSY)
  jz spi_send_data_wait
  lda SPI1_RX
  rtn 

delay:
  lda #0
  sto 10 
delay_loop:
  nop
  icz 10, delay_loop
  rtn


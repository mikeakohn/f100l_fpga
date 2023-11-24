.f100_l

.org 0x2000

start:
  ;; Setup stack (lsp) to point to start at 0x100.
  lda #0xff
  sto 0
  ;; Reset counter.
  lda #0
  sto 11
  ;; Point location 12 to the song.
  lda #song
  sto 12
main:
  cal toggle_led
  cal delay
  lda [12]
  cmp #0
  jz main
  sto 0x4009
  lda #1
  ads 12
  jmp main

toggle_led:
  lda 11
  neq #1
  sto 11
  sto 0x4008
  lda 0x100
  rtn

delay:
  lda #0
  sto 10
delay_loop:
  nop
  icz 10, delay_loop
  rtn

song:
  .dw 60, 64, 67, 0


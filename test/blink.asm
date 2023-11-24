.f100_l

.org 0x2000

start:
  ;; Setup stack (lsp) to point to start at 0x100.
  lda #0xff
  sto 0
  ;; Reset LED value.
  lda #0
  sto 11
main:
  cal toggle_led
  cal delay
  jmp main

toggle_led:
  lda 11
  neq #1
  sto 11
  sto 0x4008
  rtn

delay:
  lda #0
  sto 10
delay_loop:
  nop
  icz 10, delay_loop
  rtn


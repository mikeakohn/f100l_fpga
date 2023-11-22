.f100_l

.org 0x2000

start:
  lda #0
  sto 10
main:
  neq #1
  sto 0x4008
delay_1:
  icz 10, delay_1
  neq #1
  sto 0x4008
delay_2:
  icz 10, delay_2
  jmp main


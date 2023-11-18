.f100_l

.org 0x2000

main:
  lda #0x0f01
  sto 5
  lda #0x3050
  setm
  ;srl.d #8, 5
  sll.d #8, 5
  lda 5
  halt


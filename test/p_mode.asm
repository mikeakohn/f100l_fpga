.f100_l

.org 0x2000

main:
  lda #20
  sto 5
  lda #0x55
  sto [5]-
  ;lda #7
  ;sto [5]+
  ;lda #0x11
  lda 20
  halt


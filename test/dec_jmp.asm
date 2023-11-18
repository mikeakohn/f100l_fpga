.f100_l

.org 0x2000

main:
  lda #0xfffd
  sto 5
  lda #0
loop:
  add #1 
  icz 5, loop
  halt


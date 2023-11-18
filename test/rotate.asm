.f100_l

.org 0x2000

main:
  lda #0xfffd
  sto 5
  ;lda #1
  lda #0x8000
loop:
  ;sre #2, a
  sle #2, a
  icz 5, loop
  halt


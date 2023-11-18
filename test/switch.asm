.f100_l

.org 0x2000

main:
  lda #3 * 2
  sjm
switch:
  lda #0x01
  halt
  lda #0x40
  halt
  lda #0x80
  halt
switch_end:
  halt


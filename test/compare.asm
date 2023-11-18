.f100_l

.org 0x2000

main:
  lda #21
  ;clrm

  cmp #21
  jeq same

  lda #0x100
  halt

same:
  lda #0x80
  halt


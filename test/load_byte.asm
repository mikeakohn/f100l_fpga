.f100_l

main:
  lda #0x19
  sto 1
  lda #0x20
  ;add 1
  ;lda 1
  ;add #1
  ads 1
  sll 2, 0x0001
  lda 1
  lda #-16
  sra 3, a
  halt


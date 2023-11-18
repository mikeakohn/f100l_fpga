.f100_l

.org 0x2000

main:
  lda #21
  nop
  ;jmp long label_3
  jcs #0, a, label_2

label_1:
  set #15, a
  ;lda #0x0400
  halt

label_2:
  set #14, a
  ;lda #4
  halt

label_3:
  set #13, a
  ;lda #8
  halt


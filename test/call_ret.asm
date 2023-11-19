.f100_l

.org 0x2000

main:
  ;; Setup stack ptr.
  lda #0xff
  sto long 0
  ;; Setup for location 5 + 6.
  lda #0x21
  sto 5
  lda #0x35
  sto 6

  set f, cr
  cal long add_nums
  //lda 5
  setm
  sll.d #16, cr
  halt

add_nums:
  clr f, cr
  lda 6
  ads 5
  lda 0x101
  //rtc
  rtn


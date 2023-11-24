// Ferrati F100-L FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023 by Michael Kohn

// This is a hardcoded program that blinks an external LED.

module rom
(
  input  [9:0] address,
  output [15:0] data_out
);

reg [15:0] data;
assign data_out = data;

always @(address) begin
  case (address)
    // lda #0x00ff
    0: data <= 16'h8000;
    1: data <= 16'h00ff;
    // sto 0x0000
    2: data <= 16'h4800;
    3: data <= 16'h0000;
    // lda #0x0000
    4: data <= 16'h8000;
    5: data <= 16'h0000;
    // sto 0x00b
    6: data <= 16'h400b;
    // lda #0x2029
    7: data <= 16'h8000;
    8: data <= 16'h2029;
    // sto 0x00c
    9: data <= 16'h400c;
    // cal 0x201a
    10: data <= 16'h2800;
    11: data <= 16'h201a;
    // cal 0x2022
    12: data <= 16'h2800;
    13: data <= 16'h2022;
    // lda [0x0c]
    14: data <= 16'h880c;
    // cmp #0x0000
    15: data <= 16'hb000;
    16: data <= 16'h0000;
    // jbs z, cr, 0x200a
    17: data <= 16'h0191;
    18: data <= 16'h200a;
    // sto 0x4009
    19: data <= 16'h4800;
    20: data <= 16'h4009;
    // lda #0x0001
    21: data <= 16'h8000;
    22: data <= 16'h0001;
    // ads 0x00c
    23: data <= 16'h500c;
    // jmp 0x200a
    24: data <= 16'hf800;
    25: data <= 16'h200a;
    // lda 0x00b
    26: data <= 16'h800b;
    // neq #0x0001
    27: data <= 16'hd000;
    28: data <= 16'h0001;
    // sto 0x00b
    29: data <= 16'h400b;
    // sto 0x4008
    30: data <= 16'h4800;
    31: data <= 16'h4008;
    // lda 0x100
    32: data <= 16'h8100;
    // rtn
    33: data <= 16'h3000;
    // lda #0x0000
    34: data <= 16'h8000;
    35: data <= 16'h0000;
    // sto 0x00a
    36: data <= 16'h400a;
    // nop
    37: data <= 16'hf000;
    // icz 0x00a, 0x2025
    38: data <= 16'h700a;
    39: data <= 16'h2025;
    // rtn
    40: data <= 16'h3000;
    // data
    41: data <= 16'h003c;
    42: data <= 16'h0040;
    43: data <= 16'h0043;
    44: data <= 16'h0000;
    default: data <= 0;
  endcase
end

endmodule


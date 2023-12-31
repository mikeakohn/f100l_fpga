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
  input  [10:0] address,
  output reg [15:0] data_out,
  input clk
);

reg [15:0] memory [2047:0];

initial begin
  $readmemh("rom.txt", memory);
end

always @(posedge clk) begin
  data_out <= memory[address];
end

endmodule


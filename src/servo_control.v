// Ferrati F100-L FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023 by Michael Kohn

module servo_control
(
  input  raw_clk,
  output [3:0] servos,
  output [15:0] servo_value_0,
  output [15:0] servo_value_1,
  output [15:0] servo_value_2,
  output [15:0] servo_value_3
);

reg [15:0] servo_curr_0;
reg [15:0] servo_curr_1;
reg [15:0] servo_curr_2;
reg [15:0] servo_curr_3;

reg [3:0] servos_state;
assign servos = servos_state;

reg [17:0] count;

always @(posedge raw_clk) begin
  if (count == 240000) begin
    count <= 0;
    servos_state <= 4'hf;
    servo_curr_0 <= servo_value_0;
    servo_curr_1 <= servo_value_1;
    servo_curr_2 <= servo_value_2;
    servo_curr_3 <= servo_value_3;
  end else if (count == 24000) begin
    servos_state <= 0;
  end else begin
    if (count == servo_curr_0) servos_state[0] <= 0;
    if (count == servo_curr_1) servos_state[1] <= 0;
    if (count == servo_curr_2) servos_state[2] <= 0;
    if (count == servo_curr_3) servos_state[3] <= 0;

    count <= count + 1;
  end

end

endmodule


// Ferrati F100-L FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023 by Michael Kohn

module peripherals
(
  input enable,
  input [5:0] address,
  input [15:0] data_in,
  output reg [15:0] data_out,
  output [7:0] debug,
  input  write_enable,
  input  clk,
  input  raw_clk,
  output [3:0] servos,
  output speaker_p,
  output speaker_m,
  output ioport_0,
  output ioport_1,
  output ioport_2,
  output ioport_3,
  output ioport_4,
  input  button_0,
  input  reset,
  output spi_clk_0,
  output spi_mosi_0,
  input  spi_miso_0,
  output spi_clk_1,
  output spi_mosi_1,
  input  spi_miso_1
);

reg [7:0] storage [3:0];

reg [15:0] speaker_value_high;
reg [15:0] speaker_value_curr;
reg [7:0]  buttons;

reg speaker_toggle;
reg speaker_value_p;
reg speaker_value_m;
assign speaker_p = speaker_value_p;
assign speaker_m = speaker_value_m;

reg [7:0] ioport_a = 0;
assign ioport_0 = ioport_a[0];
reg [7:0] ioport_b = 0; // 8'hf0;
assign ioport_1 = ioport_b[0];
assign ioport_2 = ioport_b[1];
assign ioport_3 = ioport_b[2];
assign ioport_4 = ioport_b[3];

//assign debug = ioport_b;
assign debug = 0;

// SPI 0.
wire [15:0] spi_rx_buffer_0;
reg  [15:0] spi_tx_buffer_0;
wire spi_busy_0;
reg spi_start_0 = 0;
reg spi_width_16_0 = 0;
reg [3:0] spi_divisor_0 = 0;

// SPI 1.
wire [15:0] spi_rx_buffer_1;
reg  [15:0] spi_tx_buffer_1;
wire spi_busy_1;
reg spi_start_1 = 0;
reg spi_width_16_1 = 0;
reg [3:0] spi_divisor_1 = 0;

reg [15:0] servo_value_0;
reg [15:0] servo_value_1;
reg [15:0] servo_value_2;
reg [15:0] servo_value_3;

reg [15:0] mandelbrot_r;
reg [15:0] mandelbrot_i;
wire mandelbrot_busy;
reg mandelbrot_start;
wire [3:0] mandelbrot_result;

always @(button_0) begin
  buttons = { 7'b0, ~button_0 };
end

always @(posedge raw_clk) begin
  if (speaker_value_high == 16'b0) begin
    speaker_value_curr <= 0;
    speaker_value_p <= 0;
    speaker_value_m <= 0;
  end else begin
    speaker_value_curr <= speaker_value_curr + 1'b1;

    if (speaker_value_curr == speaker_value_high) begin
      speaker_value_curr <= 0;
      speaker_toggle <= ~speaker_toggle;

      speaker_value_p <= speaker_toggle;
      speaker_value_m <= ~speaker_toggle;
    end
  end
end

// FIXME: Fix this...
// This should be able to be clk instead of raw_clk, but it seems that
// two consecutive writes this module keeps stale data in data_in. So
// lda #6
// sto 0x4008
// lda #128
// sto 0x400a
// will put 6 into both 0x4008 and 0x400a
// Wiring to RAM in between keeps data_in with the correct result.
always @(posedge raw_clk) begin
//always @(posedge enable) begin
  if (reset) speaker_value_high <= 0;

  if (write_enable) begin
    case (address[5:0])
      5'h1: spi_tx_buffer_0 <= data_in;
      5'h3:
        begin
          if (data_in[1] == 1) spi_start_0 <= 1;
          spi_width_16_0 <= data_in[2];
          spi_divisor_0 <= data_in[7:4];
        end
      5'h4: spi_tx_buffer_1 <= data_in;
      5'h6:
        begin
          if (data_in[1] == 1) spi_start_1 <= 1;
          spi_width_16_1 <= data_in[2];
          spi_divisor_1 <= data_in[7:4];
        end
      5'h8: ioport_a <= data_in;
      5'h9:
        begin
          case (data_in[7:0])
            60: speaker_value_high <= 45866; // C4  261.63
            61: speaker_value_high <= 43293; // C#4 277.18
            62: speaker_value_high <= 40863; // D4 293.66
            63: speaker_value_high <= 38569; // D#4 311.13
            64: speaker_value_high <= 36404; // E4 329.63
            65: speaker_value_high <= 34361; // F4 349.23
            66: speaker_value_high <= 32433; // F#4 369.99
            67: speaker_value_high <= 30612; // G4 392.00
            68: speaker_value_high <= 28894; // G#4 415.30
            69: speaker_value_high <= 27272; // A4  440.00
            70: speaker_value_high <= 25742; // A#4 466.16
            71: speaker_value_high <= 24297; // B4 493.88
            72: speaker_value_high <= 22933; // C5 523.25
            73: speaker_value_high <= 21646; // C#5 554.37
            74: speaker_value_high <= 20431; // D5 587.33
            75: speaker_value_high <= 19284; // D#5 622.25
            76: speaker_value_high <= 18202; // E5 659.26
            77: speaker_value_high <= 17180; // F5 698.46
            78: speaker_value_high <= 16216; // F#5 739.99
            79: speaker_value_high <= 15306; // G5 783.99
            80: speaker_value_high <= 14447; // G#5 830.61
            81: speaker_value_high <= 13636; // A5 880.00
            82: speaker_value_high <= 12870; // A#5 932.33
            83: speaker_value_high <= 12148; // B5 987.77
            84: speaker_value_high <= 11466; // C6 1046.50
            85: speaker_value_high <= 10823; // C#6 1108.73
            86: speaker_value_high <= 10215; // D6 1174.66
            87: speaker_value_high <= 9642;  // D#6 1244.51
            88: speaker_value_high <= 9101;  // E6 1318.51
            89: speaker_value_high <= 8590;  // F6 1396.91
            90: speaker_value_high <= 8108;  // F#6 1479.98
            91: speaker_value_high <= 7653;  // G6 1567.98
            92: speaker_value_high <= 7223;  // G#6 1661.22
            93: speaker_value_high <= 6818;  // A6 1760.00
            94: speaker_value_high <= 6435;  // A#6 1864.66
            95: speaker_value_high <= 6074;  // B6 1975.53
            96: speaker_value_high <= 5733;  // C7 2093.00
            default: speaker_value_high <= 0;
          endcase
        end
      5'ha: ioport_b <= data_in;
      5'hb: mandelbrot_r <= data_in;
      5'hc: mandelbrot_i <= data_in;
      5'hd: if (data_in[1] == 1) mandelbrot_start <= 1;
      5'h10: servo_value_0 <= data_in;
      5'h11: servo_value_1 <= data_in;
      5'h12: servo_value_2 <= data_in;
      5'h13: servo_value_3 <= data_in;
    endcase
  end else begin
    if (spi_start_0 && spi_busy_0) spi_start_0 <= 0;
    if (spi_start_1 && spi_busy_1) spi_start_1 <= 0;
    if (mandelbrot_start && mandelbrot_busy) mandelbrot_start <= 0;

    if (enable) begin
      case (address[5:0])
        5'h0: data_out <= buttons;
        5'h1: data_out <= spi_tx_buffer_0;
        5'h2: data_out <= spi_rx_buffer_0;
        5'h3: data_out <= { spi_divisor_0, 1'b0, spi_width_16_0, 1'b0, spi_busy_0 };
        5'h4: data_out <= spi_tx_buffer_1;
        5'h5: data_out <= spi_rx_buffer_1;
        5'h6: data_out <= { spi_divisor_1, 1'b0, spi_width_16_1, 1'b0, spi_busy_1 };
        5'h8: data_out <= ioport_a;
        5'ha: data_out <= ioport_b;
        5'hb: data_out <= mandelbrot_r;
        5'hc: data_out <= mandelbrot_i;
        5'hd: data_out <= { 7'b0000000, mandelbrot_busy };
        5'he: data_out <= { 12'b00000000000, mandelbrot_result };
        5'h10: data_out <= servo_value_0;
        5'h11: data_out <= servo_value_1;
        5'h12: data_out <= servo_value_2;
        5'h13: data_out <= servo_value_3;
        default: data_out <= 0;
      endcase
    end
  end
end

spi spi_0
(
  .raw_clk  (raw_clk),
  .divisor  (spi_divisor_0),
  .start    (spi_start_0),
  .width_16 (spi_width_16_0),
  .data_tx  (spi_tx_buffer_0),
  .data_rx  (spi_rx_buffer_0),
  .busy     (spi_busy_0),
  .sclk     (spi_clk_0),
  .mosi     (spi_mosi_0),
  .miso     (spi_miso_0)
);

spi spi_1
(
  .raw_clk  (raw_clk),
  .divisor  (spi_divisor_1),
  .start    (spi_start_1),
  .width_16 (spi_width_16_1),
  .data_tx  (spi_tx_buffer_1),
  .data_rx  (spi_rx_buffer_1),
  .busy     (spi_busy_1),
  .sclk     (spi_clk_1),
  .mosi     (spi_mosi_1),
  .miso     (spi_miso_1)
);

servo_control servo_control_0
(
  .raw_clk       (raw_clk),
  .servos        (servos),
  .servo_value_0 (servo_value_0),
  .servo_value_1 (servo_value_1),
  .servo_value_2 (servo_value_2),
  .servo_value_3 (servo_value_3)
);

mandelbrot mandelbrot_0
(
  .raw_clk  (raw_clk),
  .start    (mandelbrot_start),
  .curr_r   (mandelbrot_r),
  .curr_i   (mandelbrot_i),
  .result   (mandelbrot_result),
  .busy     (mandelbrot_busy)
);

endmodule


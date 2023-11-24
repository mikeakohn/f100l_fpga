// Ferrati F100-L FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023 by Michael Kohn

module spi
(
  input raw_clk,
  input chip_select,
  input start,
  input [7:0] data_in,
  output [7:0] data_out,
  output busy,
  output sclk,
  output mosi,
  input simo
);

reg is_running = 0;
reg [3:0] clock_div;
wire clk;
assign clk = clock_div[3];

reg [1:0] state = 0;
reg [7:0] rx_buffer;
reg [7:0] tx_buffer;
reg [3:0] count;

assign data_out = rx_buffer;
assign busy = is_running;

always @(posedge raw_clk) begin
  clock_div <= clock_div + 1;
end

parameter STATE_IDLE = 0;
parameter STATE_CLOCK_OUT = 1;
parameter STATE_CLOCK_IN = 2;

always @(posedge clk) begin
  case (state)
    STATE_IDLE:
      begin
        if (start) begin
          is_running <= 1;
          state <= STATE_CLOCK_OUT;
          count <= 0;
        end else begin
          is_running <= 0;
        end
      end
    STATE_CLOCK_OUT:
      begin
        tx_buffer <= tx_buffer << 1;
        mosi <= tx_buffer[7];
        sclk <= 1;
        count <= count + 1;
        state <= STATE_CLOCK_IN;
      end
    STATE_CLOCK_IN:
      begin
        sclk <= 0;
        rx_buffer <= { rx_buffer[6:0], somi };

        if (count[3:0]) begin
          state <= STATE_IDLE;
          mosi <= 0;
        end else begin
          state <= STATE_CLOCK_OUT;
        end
      end
  endcase
end

endmodule

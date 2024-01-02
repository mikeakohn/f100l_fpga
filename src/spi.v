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
  input  raw_clk,
  input  [3:0] divisor,
  input  start,
  input  width_16,
  input  [15:0] data_tx,
  output [15:0] data_rx,
  output busy,
  output reg sclk,
  output reg mosi,
  input  miso
);

reg is_running = 0;

reg [1:0] state = 0;
reg [15:0] rx_buffer;
reg [15:0] tx_buffer;
reg [4:0] count;

assign data_rx = rx_buffer;
assign busy = is_running;

parameter STATE_IDLE    = 0;
parameter STATE_CLOCK_0 = 1;
parameter STATE_CLOCK_1 = 2;
parameter STATE_LAST    = 3;

reg [3:0] clock_counter = 0;

always @(posedge raw_clk) begin
  case (state)
    STATE_IDLE:
      begin
        if (start) begin
          if (width_16)
            tx_buffer <= data_tx;
          else
            tx_buffer[15:8] <= data_tx[7:0];

          rx_buffer <= 8'h00;
          clock_counter <= 0;

          is_running <= 1;
          state <= STATE_CLOCK_0;
          count <= 0;
        end else begin
          is_running <= 0;
          mosi <= 0;
          sclk <= 0;
        end
      end
    STATE_CLOCK_0:
      begin
        sclk <= 0;

        //if (count != 0) rx_buffer <= { rx_buffer[6:0], miso };
        //rx_buffer <= { rx_buffer[6:0], miso };

        rx_buffer[7:1] <= rx_buffer[6:0];
        rx_buffer[0] <= miso;

        tx_buffer <= tx_buffer << 1;
        mosi <= tx_buffer[15];

        if (clock_counter == divisor) begin
          clock_counter <= 0;
          count <= count + 1;
          state <= STATE_CLOCK_1;
        end else begin
          clock_counter <= clock_counter + 1;
        end
      end
    STATE_CLOCK_1:
      begin
        sclk <= 1;

        if (clock_counter == divisor) begin
          if (width_16 == 0 && count[3]) begin
            state <= STATE_LAST;
          end else if (width_16 == 1 && count[4]) begin
            state <= STATE_LAST;
          end else begin
            clock_counter <= 0;
            state <= STATE_CLOCK_0;
          end
        end else begin
          clock_counter <= clock_counter + 1;
        end
      end
    STATE_LAST:
      begin
        sclk <= 0;
        //rx_buffer <= { rx_buffer[6:0], miso };
        //rx_buffer <= { rx_buffer[6:0], 1 };
        rx_buffer[7:1] <= rx_buffer[6:0];
        rx_buffer[0] <= miso;
        state <= STATE_IDLE;
      end
  endcase
end

endmodule


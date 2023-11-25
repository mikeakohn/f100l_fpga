// Ferrati F100-L FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023 by Michael Kohn

module f100l
(
  output [7:0] leds,
  output [3:0] column,
  input raw_clk,
  output eeprom_cs,
  output eeprom_clk,
  output eeprom_di,
  input  eeprom_do,
  output speaker_p,
  output speaker_m,
  output ioport_0,
  output ioport_1,
  output ioport_2,
  output ioport_3,
  input  button_reset,
  input  button_halt,
  input  button_program_select,
  input  button_0,
  output spi_clk,
  output spi_mosi,
  input  spi_miso
);

// iceFUN 8x4 LEDs used for debugging.
reg [7:0] leds_value;
reg [3:0] column_value;

assign leds = leds_value;
assign column = column_value;

// Memory bus (ROM, RAM, peripherals).
reg [15:0] mem_address = 0;
reg [15:0] mem_write = 0;
reg [3:0] mem_write_mask = 0;
wire [15:0] mem_read;
//wire mem_data_ready;
reg mem_bus_enable = 0;
reg mem_write_enable = 0;

// Clock.
reg [21:0] count = 0;
reg [5:0]  state = 0;
reg [4:0] clock_div;
reg [14:0] delay_loop;
wire clk;
assign clk = clock_div[1];

// Registers.
reg [15:0] pc = 0;
reg [15:0] accum = 0;
reg [15:0] lsp;
reg [15:0] cr;
reg [15:0] data;
reg [16:0] temp;
reg [31:0] temp32;

reg [8:0] flag_unused;
wire flag_f;
wire flag_m;
wire flag_c;
wire flag_s;
wire flag_v;
wire flag_z;
wire flag_i;

assign flag_f = cr[6];
assign flag_m = cr[5];
assign flag_c = cr[4];
assign flag_s = cr[3];
assign flag_v = cr[2];
assign flag_z = cr[1];
assign flag_i = cr[0];

parameter CR_F = 6;
parameter CR_M = 5;
parameter CR_C = 4;
parameter CR_S = 3;
parameter CR_V = 2;
parameter CR_Z = 1;
parameter CR_I = 0;

// Load / Store.
reg [15:0] ea;
reg [2:0] dest;

// Instruction
reg [15:0] instruction;
wire [1:0] r_mode;
wire [1:0] s_mode;
wire [1:0] j_mode;
wire [3:0] bits;
wire [4:0] bits5;
reg do_jump;
reg do_ptr_writeback;

assign r_mode = instruction[9:8];
assign s_mode = instruction[7:6];
assign j_mode = instruction[5:4];
assign bits   = instruction[3:0];
assign bits5  = instruction[4:0];

// Upper 4 bits of the instruction.
wire [3:0] alu_op;
assign alu_op = instruction[15:12];

// Eeprom.
reg [10:0] eeprom_count;
wire [7:0] eeprom_data_out;
reg  [7:0] eeprom_lsb;
//reg [15:0] eeprom_data_in;
reg [10:0] eeprom_address;
reg [15:0] eeprom_mem_address;
reg eeprom_strobe = 0;
wire eeprom_ready;

// Debug.
//reg [7:0] debug_0 = 0;
//reg [7:0] debug_1 = 0;
//reg [7:0] debug_2 = 0;
//reg [7:0] debug_3 = 0;

// This block is simply a clock divider for the raw_clk.
always @(posedge raw_clk) begin
  count <= count + 1;
  clock_div <= clock_div + 1;
end

// Debug: This block simply drives the 8x4 LEDs.
always @(posedge raw_clk) begin
  case (count[9:7])
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~instruction[7:0]; end
    //3'b010: begin column_value <= 4'b1011; leds_value <= ~instruction[15:8]; end
    3'b000: begin column_value <= 4'b0111; leds_value <= ~accum[7:0]; end
    3'b010: begin column_value <= 4'b1011; leds_value <= ~accum[15:8]; end
    3'b100: begin column_value <= 4'b1101; leds_value <= ~pc[7:0]; end
    3'b110: begin column_value <= 4'b1110; leds_value <= ~state; end
    default: begin column_value <= 4'b1111; leds_value <= 8'hff; end
  endcase
end

parameter STATE_RESET =                 0;
parameter STATE_DELAY_LOOP =            1;
parameter STATE_FETCH_OP_0 =            2;
parameter STATE_FETCH_OP_1 =            3;
parameter STATE_START_DECODE =          4;
parameter STATE_BIT_OP_READ_W_0 =       5;
parameter STATE_BIT_OP_READ_W_1 =       6;
parameter STATE_BIT_OP_READ_W_2 =       7;
parameter STATE_BIT_OP_READ_W_3 =       8;
parameter STATE_BIT_OP_EXECUTE =        9;
parameter STATE_BIT_OP_WRITE_BACK =    10;
parameter STATE_BIT_32_OP_WRITE_BACK = 11;
parameter STATE_WRITE_BACK_JUMP_W_0 =  12;
parameter STATE_WRITE_BACK_JUMP_W_1 =  13;
parameter STATE_FETCH_JUMP_W_0 =       14;
parameter STATE_FETCH_JUMP_W_1 =       15;
parameter STATE_ALU_FETCH_PTR_0 =      16;
parameter STATE_ALU_FETCH_PTR_1 =      17;
parameter STATE_ALU_WRITE_BACK_PTR_0 = 18;
parameter STATE_ALU_WRITE_BACK_PTR_1 = 19;
parameter STATE_ALU_FETCH_DATA_0 =     20;
parameter STATE_ALU_FETCH_DATA_1 =     21;
parameter STATE_ALU_EXECUTE =          22;
parameter STATE_WRITE_BACK =           23;
parameter STATE_WRITE_BACK_1 =         24;
parameter STATE_CAL_GET_LSP_1 =        25;
parameter STATE_CAL_PUSH_JMP_0 =       26;
parameter STATE_CAL_PUSH_JMP_1 =       27;
parameter STATE_CAL_PUSH_CR_0 =        28;
parameter STATE_CAL_PUSH_CR_1 =        29;
parameter STATE_CAL_WRITE_LSP_0 =      30;
parameter STATE_CAL_WRITE_LSP_1 =      31;
parameter STATE_POP_FETCH_LSP_1 =      32;
parameter STATE_POP_CR_0 =             33;
parameter STATE_POP_CR_1 =             34;
parameter STATE_POP_PC_0 =             35;
parameter STATE_POP_PC_1 =             36;
parameter STATE_POP_WRITE_LSP_0 =      37;
parameter STATE_POP_WRITE_LSP_1 =      38;

parameter STATE_HALTED =       40;
parameter STATE_ERROR =        41;
parameter STATE_EEPROM_START = 42;
parameter STATE_EEPROM_READ =  43;
parameter STATE_EEPROM_WAIT =  44;
parameter STATE_EEPROM_WRITE = 45;
parameter STATE_EEPROM_DONE =  46;

parameter STATE_DEBUG =        47;
parameter STATE_MEM_DEBUG_0 =  48;
parameter STATE_MEM_DEBUG_1 =  49;
parameter STATE_MEM_DEBUG_2 =  50;
parameter STATE_MEM_DEBUG_3 =  51;

parameter DEST_NONE = 0;
parameter DEST_A    = 1;
parameter DEST_PC   = 2;
parameter DEST_EA   = 3;
parameter DEST_CALL = 4;
parameter DEST_ICZ  = 5;

// Note: 0x3000 and 0xe000 appear to be open. Could add an "OR" instruction
// and something else.
parameter OP_ADD = 4'h9;
parameter OP_ADS = 4'h5;
parameter OP_AND = 4'hc;
parameter OP_CAL = 4'h2;
parameter OP_CMP = 4'hb;
parameter OP_ICZ = 4'h7;
parameter OP_JMP = 4'hf;
parameter OP_LDA = 4'h8;
parameter OP_NEQ = 4'hd;
parameter OP_SBS = 4'h6;
parameter OP_STO = 4'h4;
parameter OP_SUB = 4'ha;

function signed [15:0] sign16(input signed [15:0] data);
  sign16 = data;
endfunction

function signed [31:0] sign32(input signed [31:0] data);
  sign32 = data;
endfunction

// This block is the main CPU instruction execute state machine.
always @(posedge clk) begin
  if (!button_reset)
    state <= STATE_RESET;
  else if (!button_halt)
    state <= STATE_HALTED;
  else
    case (state)
      STATE_RESET:
        begin
          mem_address <= 0;
          mem_write_enable <= 0;
          mem_write <= 0;
          instruction <= 0;
          delay_loop <= 12000;
          //eeprom_strobe <= 0;
          state <= STATE_DELAY_LOOP;
          accum <= 0;
          cr <= 0;
        end
      STATE_DELAY_LOOP:
        begin
          // This is probably not needed. The chip starts up fine without it.
          if (delay_loop == 0) begin

            // If button is not pushed, start rom.v code otherwise use EEPROM.
            if (button_program_select) begin
              pc <= 16'h2000;
              state <= STATE_FETCH_OP_0;
            end else begin
              pc <= 16'h6000;
              state <= STATE_EEPROM_START;
            end
          end else begin
            delay_loop <= delay_loop - 1;
          end
        end
      STATE_FETCH_OP_0:
        begin
          do_ptr_writeback <= 0;
          do_jump <= 0;
          mem_bus_enable <= 1;
          mem_write_enable <= 0;
          mem_address <= pc;
          pc <= pc + 1;
          state <= STATE_FETCH_OP_1;
        end
      STATE_FETCH_OP_1:
        begin
          mem_bus_enable <= 0;
          instruction <= mem_read;
          state <= STATE_START_DECODE;
        end
      STATE_START_DECODE:
        begin
          case (instruction[15:12])
            4'b0000:
              case (instruction[11:10])
                2'b00:
                  begin
                    case (r_mode)
                      2'b01:
                        begin
                          data <= cr;
                          state <= STATE_BIT_OP_EXECUTE;
                        end
                      2'b11:
                        begin
                          state <= STATE_BIT_OP_READ_W_0;
                        end
                      default:
                        begin
                          data <= accum;
                          state <= STATE_BIT_OP_EXECUTE;
                        end
                    endcase
                  end
                2'b01:
                  begin
                    state <= STATE_HALTED;
                  end
              endcase
            4'b0001:
              begin
                // sjm: docs say pc <- pc + 1 + A, but pc is already pc + 1.
                pc <= pc + accum;
                state <= STATE_FETCH_OP_0;
              end
            4'b0011:
              begin
                // rtn, rtc (pop cr, pop pc).
                mem_bus_enable <= 1;
                mem_write_enable <= 0;
                mem_address <= 0;
                state <= STATE_POP_FETCH_LSP_1;
              end
            default:
              // ALU.
              begin
                if (instruction[11] == 0) begin
                  if (instruction[10:0] != 0) begin
                    // N (short address).
                    ea <= instruction[10:0];
                  end else begin
                    // #D aka ,D
                    ea <= pc;
                    pc <= pc + 1;
                  end

                  state <= STATE_ALU_FETCH_DATA_0;
                end else begin
                  if (instruction[7:0] != 0) begin
                    //  [P], [P]+, [P]- aka /P, /P+, /P-
                    if (instruction[8] == 1) do_ptr_writeback <= 1;

                    ea <= instruction[7:0];
                    temp <= instruction[7:0];
                  end else begin
                    // long W aka .W
                    ea <= pc;
                    pc <= pc + 1;
                  end

                  state <= STATE_ALU_FETCH_PTR_0;
                end
              end
          endcase
        end
      STATE_BIT_OP_READ_W_0:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 0;
          mem_address <= pc;
          ea <= pc;
          pc <= pc + 1;
          state <= STATE_BIT_OP_READ_W_1;
        end
      STATE_BIT_OP_READ_W_1:
        begin
          mem_bus_enable <= 0;
          ea <= mem_read;
          state <= STATE_BIT_OP_READ_W_2;
        end
      STATE_BIT_OP_READ_W_2:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 0;
          mem_address <= ea;
          state <= STATE_BIT_OP_READ_W_3;
        end
      STATE_BIT_OP_READ_W_3:
        begin
          mem_bus_enable <= 0;
          temp <= mem_read;
          state <= STATE_BIT_OP_EXECUTE;
        end
      STATE_BIT_OP_EXECUTE:
        begin
          case (s_mode)
            2'b00:
              begin
                // Shift right: sra, srl, sre.
                if (flag_m == 0)
                  begin
                    // Shift left: sra, srl, sre.
                    case (j_mode)
                      // x0: arithmetic, 10: logical, 11: rotate
                      2'b10: temp <= data >> bits;
                      2'b11:
                        begin
                          case (bits)
                             0: temp <= data;
                             1: temp <= { data[0],    data[15:1]  };
                             2: temp <= { data[1:0],  data[15:2]  };
                             3: temp <= { data[2:0],  data[15:3]  };
                             4: temp <= { data[3:0],  data[15:4]  };
                             5: temp <= { data[4:0],  data[15:5]  };
                             6: temp <= { data[5:0],  data[15:6]  };
                             7: temp <= { data[6:0],  data[15:7]  };
                             8: temp <= { data[7:0],  data[15:8]  };
                             9: temp <= { data[8:0],  data[15:9]  };
                            10: temp <= { data[9:0],  data[15:10] };
                            11: temp <= { data[10:0], data[15:11] };
                            12: temp <= { data[11:0], data[15:12] };
                            13: temp <= { data[12:0], data[15:13] };
                            14: temp <= { data[13:0], data[15:14] };
                            15: temp <= { data[14:0], data[15]    };
                          endcase
                        end
                      default: temp <= sign16(data) >>> bits;
                    endcase
                    state <= STATE_BIT_OP_WRITE_BACK;
                  end
                else
                  begin
                    // Shift right: sra.d, srl.d.
                    case (j_mode[1])
                      0: temp32 <= { accum, data[15:0] } >> bits5;
                      1: temp32 <= sign32({ accum, data[15:0] }) >>> bits5;
                    endcase
                    state <= STATE_BIT_32_OP_WRITE_BACK;
                  end
              end
            2'b01:
              begin
                if (flag_m == 0)
                  begin
                    // Shift left: sla, sll, sle.
                    case (j_mode)
                      // x0: arithmetic, 10: logical, 11: rotate
                      2'b10: temp <= data << bits;
                      2'b11:
                        begin
                         case (bits)
                            0: temp <= data;
                            1: temp <= { data[14:0], data[15]    };
                            2: temp <= { data[13:0], data[15:14] };
                            3: temp <= { data[12:0], data[15:13] };
                            4: temp <= { data[11:0], data[15:12] };
                            5: temp <= { data[10:0], data[15:11] };
                            6: temp <= { data[9:0],  data[15:10] };
                            7: temp <= { data[8:0],  data[15:9]  };
                            8: temp <= { data[7:0],  data[15:8]  };
                            9: temp <= { data[6:0],  data[15:7]  };
                           10: temp <= { data[5:0],  data[15:6]  };
                           11: temp <= { data[4:0],  data[15:5]  };
                           12: temp <= { data[3:0],  data[15:4]  };
                           13: temp <= { data[2:0],  data[15:3]  };
                           14: temp <= { data[1:0],  data[15:2]  };
                           15: temp <= { data[0],    data[15:1]  };
                         endcase
                        end
                      default: temp <= data << bits;
                    endcase
                    state <= STATE_BIT_OP_WRITE_BACK;
                  end
                else
                  begin
                    // Shift left: sla.d, sll.d.
                    case (j_mode[1])
                      0: temp32 <= { accum, data[15:0] } << bits5;
                      1: temp32 <= { accum, data[15:0] } << bits5;
                    endcase
                    state <= STATE_BIT_32_OP_WRITE_BACK;
                  end
              end
            2'b10:
              // jbc, jbs, jcs, jsc.
              begin
                case (r_mode)
                  2'b01:
                    begin
                      // cr.
                      if (data[bits] == j_mode[0]) begin
                        do_jump <= 1;
                        if (j_mode[1]) cr[bits] <= ~j_mode[0];
                      end
                      state <= STATE_FETCH_JUMP_W_0;
                    end
                  2'b11:
                    begin
                      // W.
                      if (data[bits] == j_mode[0]) begin
                        do_jump <= 1;
                        if (j_mode[1]) begin
                          data[bits] <= ~j_mode[0];
                          state <= STATE_WRITE_BACK_JUMP_W_0;
                        end else begin
                          state <= STATE_FETCH_JUMP_W_0;
                        end
                      end else begin
                        state <= STATE_FETCH_JUMP_W_0;
                      end
                    end
                  default:
                    begin
                      // accum.
                      if (accum[bits] == j_mode[0]) begin
                        do_jump <= 1;
                        if (j_mode[1]) accum[bits] <= ~j_mode[0];
                      end
                      state <= STATE_FETCH_JUMP_W_0;
                    end
                endcase
              end
            2'b11:
              begin
                // clr, set.
                case (r_mode)
                  2'b01:
                    begin
                      cr[bits] <= ~j_mode[0];
                      state <= STATE_FETCH_OP_0;
                    end
                  2'b11:
                    begin
                      temp[bits] <= ~j_mode[0];
                      state <= STATE_BIT_OP_WRITE_BACK;
                    end
                  default:
                    begin
                      accum[bits] <= ~j_mode[0];
                      state <= STATE_FETCH_OP_0;
                    end
                endcase
              end
          endcase
        end
      STATE_BIT_OP_WRITE_BACK:
        begin
          case (r_mode)
            2'b01:
              begin
                cr <= temp;
                state <= STATE_FETCH_OP_0;
              end
            2'b11:
              begin
                mem_bus_enable <= 1;
                mem_write_enable <= 1;
                mem_write <= temp;
                mem_address <= ea;
                state <= STATE_WRITE_BACK_1;
              end
            default:
              begin
                accum <= temp;
                state <= STATE_FETCH_OP_0;
              end
          endcase
          cr[CR_S] <= temp[15];
          // Docs say Z is meaningless. It has meaning here.
          cr[CR_Z] <= temp == 0;
          //cr[CR_V] <= ?; // FIXME?
        end
      STATE_BIT_32_OP_WRITE_BACK:
        begin
          case (r_mode)
            2'b01:
              begin
                cr <= temp32[15:0];
                state <= STATE_FETCH_OP_0;
              end
            2'b11:
              begin
                mem_bus_enable <= 1;
                mem_write_enable <= 1;
                mem_write <= temp32[15:0];
                mem_address <= ea;
                state <= STATE_WRITE_BACK_1;
              end
            default:
              begin
                // FIXME: This is supposed to be "Operand Register"? What
                // is this?
                //accum <= temp32[15:0];
                state <= STATE_FETCH_OP_0;
              end
          endcase

          accum <= temp32[31:16];
        end
      STATE_WRITE_BACK_JUMP_W_0:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 0;
          mem_address <= ea;
          mem_write <= temp;
          state <= STATE_WRITE_BACK_JUMP_W_1;
        end
      STATE_WRITE_BACK_JUMP_W_1:
        begin
          mem_bus_enable <= 0;
          mem_write_enable <= 0;
          state <= STATE_FETCH_JUMP_W_0;
        end
      STATE_FETCH_JUMP_W_0:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 0;
          mem_address <= pc;
          pc <= pc + 1;
          state <= STATE_FETCH_JUMP_W_1;
        end
      STATE_FETCH_JUMP_W_1:
        begin
          mem_bus_enable <= 0;

          if (do_jump) pc <= mem_read;

          state <= STATE_FETCH_OP_0;
        end
      STATE_ALU_FETCH_PTR_0:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 0;
          mem_address <= ea;
          state <= STATE_ALU_FETCH_PTR_1;
        end
      STATE_ALU_FETCH_PTR_1:
        begin
          mem_bus_enable <= 0;
          ea <= mem_read;

          if (do_ptr_writeback) begin
            state <= STATE_ALU_WRITE_BACK_PTR_0;
          end else begin
            state <= STATE_ALU_FETCH_DATA_0;
          end
        end
      STATE_ALU_WRITE_BACK_PTR_0:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 1;
          mem_address <= temp;

          // 01: [P]+ aka P+ (+ is done before ea is used).
          // 11: [P]- aka P- (0 is done at write-back time).
          if (instruction[9] == 0) begin
            mem_write <= ea + 1;
            ea <= ea + 1;
          end else begin
            mem_write <= ea - 1;
          end

          state <= STATE_ALU_WRITE_BACK_PTR_1;
        end
      STATE_ALU_WRITE_BACK_PTR_1:
        begin
          mem_bus_enable <= 0;
          mem_write_enable <= 0;
          state <= STATE_ALU_FETCH_DATA_0;
        end
      STATE_ALU_FETCH_DATA_0:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 0;
          mem_address <= ea;
          state <= STATE_ALU_FETCH_DATA_1;
        end
      STATE_ALU_FETCH_DATA_1:
        begin
          // FIXME: This state can be combined with execute.
          mem_bus_enable <= 0;
          data <= mem_read;
          state <= STATE_ALU_EXECUTE;
        end
      STATE_ALU_EXECUTE:
        begin
          case (alu_op)
            OP_ADD:
              begin
                if (flag_m == 0) temp <= data + accum;
                else        temp <= data + accum + flag_c;
                dest <= DEST_A;
              end
            OP_ADS:
              begin
                if (flag_m == 0) temp <= accum + data;
                else        temp <= accum + data + flag_c;
                dest <= DEST_EA;
              end
            OP_AND:
              begin
                temp <= accum & data;
                dest <= DEST_A;
              end
            OP_CAL:
              begin
                temp <= data;  // FIXME
                dest <= DEST_CALL;
              end
            OP_CMP:
              begin
                if (flag_m == 0) temp <= data - accum;
                else             temp <= data - accum + flag_c - 1;
                dest <= DEST_NONE;
                cr[CR_M] <= 1;
              end
            OP_ICZ:
              begin
                temp <= data + 1;
                dest <= DEST_ICZ;
              end
            OP_JMP:
              begin
                temp <= data;
                dest <= DEST_PC;
              end
            OP_LDA:
              begin
                temp <= data;
                dest <= DEST_A;
              end
            OP_NEQ:
              begin
                temp <= accum ^ data;
                dest <= DEST_A;
              end
            OP_SBS:
              begin
                if (flag_m == 0) temp <= data - accum;
                else        temp <= data - accum + flag_c - 1;
                dest <= DEST_EA;
              end
            OP_STO:
              begin
                temp <= accum;
                dest <= DEST_EA;
              end
            OP_SUB:
              begin
                if (flag_m == 0) temp <= data - accum;
                else        temp <= data - accum + flag_c - 1;
                dest <= DEST_A;
              end
          endcase

          state <= STATE_WRITE_BACK;
        end
      STATE_WRITE_BACK:
        begin
          cr[CR_C] <= temp[16];
          cr[CR_S] <= temp[15];
          cr[CR_Z] <= temp[15:0] == 0;

          if (alu_op == OP_SUB || alu_op == OP_SBS)
            cr[CR_V] <= (accum[15] != data[15]) && (temp[15] == accum[15]);
          else if (alu_op == OP_ADD || alu_op == OP_ADS)
            cr[CR_V] <= (accum[15] == data[15]) && (temp[15] != accum[15]);

          case (dest)
            DEST_NONE:
              begin
                state <= STATE_FETCH_OP_0;
              end
            DEST_A:
              begin
                accum <= temp;
                state <= STATE_FETCH_OP_0;
              end
            DEST_PC:
              begin
                if (instruction[11] == 1 && instruction[7:0] != 0) begin
                  pc <= temp;
                end else begin
                  pc <= ea;
                end
                state <= STATE_FETCH_OP_0;
              end
            DEST_EA:
              begin
                mem_bus_enable <= 1;
                mem_write_enable <= 1;
                mem_address <= ea;
                mem_write <= temp;
                state <= STATE_WRITE_BACK_1;
              end
            DEST_CALL:
              begin
                mem_bus_enable <= 1;
                mem_write_enable <= 0;
                mem_address <= 0;
                state <= STATE_CAL_GET_LSP_1;
              end
            DEST_ICZ:
              begin
                mem_bus_enable <= 1;
                mem_write_enable <= 1;
                mem_write <= temp;
                mem_address <= ea;
                state <= STATE_WRITE_BACK_1;
              end
          endcase
        end
      STATE_WRITE_BACK_1:
        begin
          mem_bus_enable <= 0;
          mem_write_enable <= 0;
          mem_write <= 0;

          if (alu_op == OP_ICZ) begin
            // Change instruction to: jbc z, cr, W
            instruction <= 16'b0000_0001_1000_0001;
            state <= STATE_START_DECODE;
          end else begin
            state <= STATE_FETCH_OP_0;
          end
        end
      STATE_CAL_GET_LSP_1:
        begin
          mem_bus_enable <= 0;
          lsp <= mem_read;
          state <= STATE_CAL_PUSH_JMP_0;
        end
      STATE_CAL_PUSH_JMP_0:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 1;
          mem_address <= lsp + 1;
          mem_write <= pc;
          state <= STATE_CAL_PUSH_JMP_1;
        end
      STATE_CAL_PUSH_JMP_1:
        begin
          mem_bus_enable <= 0;
          mem_write_enable <= 0;
          mem_write <= 0;
          state <= STATE_CAL_PUSH_CR_0;
        end
      STATE_CAL_PUSH_CR_0:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 1;
          mem_address <= lsp + 2;
          mem_write <= cr;
          state <= STATE_CAL_PUSH_CR_1;
        end
      STATE_CAL_PUSH_CR_1:
        begin
          mem_bus_enable <= 0;
          mem_write_enable <= 0;
          mem_write <= 0;
          state <= STATE_CAL_WRITE_LSP_0;
        end
      STATE_CAL_WRITE_LSP_0:
        begin
          // cal instruction clears m, I would guess after it pushes it?
          cr[CR_M] <= 0;

          mem_bus_enable <= 1;
          mem_write_enable <= 1;
          mem_address <= 0;
          mem_write <= lsp + 2;
          state <= STATE_CAL_WRITE_LSP_1;
        end
      STATE_CAL_WRITE_LSP_1:
        begin
          mem_bus_enable <= 0;
          mem_write_enable <= 0;
          mem_write <= 0;
          //pc <= temp;
          pc <= ea;
          state <= STATE_FETCH_OP_0;
        end
      STATE_POP_FETCH_LSP_1:
        begin
          mem_bus_enable <= 0;
          lsp <= mem_read;
          state <= STATE_POP_CR_0;
        end
      STATE_POP_CR_0:
        begin
          mem_bus_enable <= 1;
          mem_address <= lsp;
          lsp <= lsp - 1;
          state <= STATE_POP_CR_1;
        end
      STATE_POP_CR_1:
        begin
          mem_bus_enable <= 0;
          if (instruction[11] == 0) cr <= mem_read;
          state <= STATE_POP_PC_0;
        end
      STATE_POP_PC_0:
        begin
          mem_bus_enable <= 1;
          mem_address <= lsp;
          lsp <= lsp - 1;
          state <= STATE_POP_PC_1;
        end
      STATE_POP_PC_1:
        begin
          mem_bus_enable <= 0;
          pc <= mem_read;
          state <= STATE_POP_WRITE_LSP_0;
        end
      STATE_POP_WRITE_LSP_0:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 1;
          mem_address <= 0;
          mem_write <= lsp;
          state <= STATE_POP_WRITE_LSP_1;
        end
      STATE_POP_WRITE_LSP_1:
        begin
          mem_bus_enable <= 0;
          mem_write_enable <= 0;
          mem_write <= 0;
          state <= STATE_FETCH_OP_0;
        end
      STATE_HALTED:
        begin
          state <= STATE_HALTED;
        end
      STATE_ERROR:
        begin
          state <= STATE_ERROR;
        end
      STATE_EEPROM_START:
        begin
          // Initialize values for reading from SPI-like EEPROM.
          if (eeprom_ready) begin
            eeprom_mem_address <= 16'h6000;
            eeprom_count <= 0;
            state <= STATE_EEPROM_READ;
          end
        end
      STATE_EEPROM_READ:
        begin
          // Set the next EEPROM address to read from and strobe.
          eeprom_address <= eeprom_count;
          eeprom_strobe <= 1;
          eeprom_count <= eeprom_count + 1;
          state <= STATE_EEPROM_WAIT;
        end
      STATE_EEPROM_WAIT:
        begin
          // Wait until 8 bits are clocked in.
          eeprom_strobe <= 0;

          if (eeprom_ready) begin
            mem_bus_enable <= 0;

            if (eeprom_address[0] == 0) begin
              // After reading in an even byte, save to eeprom_lsb and
              // read the upper byte.
              eeprom_lsb <= eeprom_data_out;
              state <= STATE_EEPROM_READ;
            end else begin
              // After reading an odd byte, store the 16 bit value to RAM.
              mem_write <= { eeprom_data_out, eeprom_lsb };
              state <= STATE_EEPROM_WRITE;
            end
          end
        end
      STATE_EEPROM_WRITE:
        begin
          // Write value read from EEPROM into memory.
          mem_bus_enable <= 1;
          mem_write_enable <= 1;
          mem_address <= eeprom_mem_address;
          eeprom_mem_address <= eeprom_mem_address + 1;
          state <= STATE_EEPROM_DONE;
        end
      STATE_EEPROM_DONE:
        begin
          // Finish writing and read next byte if needed.
          mem_bus_enable <= 0;
          mem_write_enable <= 0;

          if (eeprom_count == 0)
            // Read in 1024 bytes.
            state <= STATE_FETCH_OP_0;
          else
            state <= STATE_EEPROM_READ;
        end
      STATE_DEBUG:
        begin
          state <= STATE_DEBUG;
        end
      STATE_MEM_DEBUG_0:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 1;
          mem_address <= 10;
          mem_write <= 8'h55;
          state <= STATE_MEM_DEBUG_1;
        end
      STATE_MEM_DEBUG_1:
        begin
          mem_bus_enable <= 0;
          mem_write_enable <= 0;
          mem_write <= 0;
          state <= STATE_MEM_DEBUG_2;
        end
      STATE_MEM_DEBUG_2:
        begin
          mem_bus_enable <= 1;
          mem_write_enable <= 0;
          mem_address <= 14'h2009;
          //mem_address <= ea;
          state <= STATE_MEM_DEBUG_3;
        end
      STATE_MEM_DEBUG_3:
        begin
          mem_bus_enable <= 0;
          accum <= mem_read;
          state <= STATE_DEBUG;
        end
    endcase
end

memory_bus memory_bus_0(
  .address      (mem_address),
  .data_in      (mem_write),
  .data_out     (mem_read),
  .bus_enable   (mem_bus_enable),
  .write_enable (mem_write_enable),
  .clk          (clk),
  .raw_clk      (raw_clk),
  .speaker_p    (speaker_p),
  .speaker_m    (speaker_m),
  .ioport_0     (ioport_0),
  .ioport_1     (ioport_1),
  .ioport_2     (ioport_2),
  .ioport_3     (ioport_3),
  .button_0     (button_0),
  .reset        (~button_reset),
  .spi_clk      (spi_clk),
  .spi_mosi     (spi_mosi),
  .spi_miso     (spi_miso)
);

eeprom eeprom_0
(
  .address    (eeprom_address),
  .strobe     (eeprom_strobe),
  .raw_clk    (raw_clk),
  .eeprom_cs  (eeprom_cs),
  .eeprom_clk (eeprom_clk),
  .eeprom_di  (eeprom_di),
  .eeprom_do  (eeprom_do),
  .ready      (eeprom_ready),
  .data_out   (eeprom_data_out)
);

endmodule


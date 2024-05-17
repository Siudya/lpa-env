/***************************************************************************************
* Copyright (c) 2020-2023 Institute of Computing Technology, Chinese Academy of Sciences
* Copyright (c) 2020-2021 Peng Cheng Laboratory
*
* DiffTest is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/
module tb_top();
import "DPI-C" function void init_flash();
import "DPI-C" function void init_mem(string bin);
import "DPI-C" function void flash_finish();
import "DPI-C" function void mem_finish();
import "DPI-C" function void time_start();
import "DPI-C" function void cycle_add();
import "DPI-C" function void time_end();

string bin_file;
string wave_type;

reg         clock;
reg         reset;
reg         io_perfInfo_dump;
wire        io_uart_out_valid;
wire [ 7:0] io_uart_out_ch;
wire        io_uart_in_valid;
reg [63:0]  cycles;
reg [63:0]  max_cycles;

initial begin
  clock = 0;
  reset = 1;
  max_cycles = 0;
  if ($test$plusargs("dump-wave")) begin
    $display("Dumping FSDB Waveform for DEBUG is active !!!");
    $fsdbAutoSwitchDumpfile(10000,"tb_top.fsdb",60);
    $fsdbDumpfile("tb_top.fsdb");
    if ($test$plusargs("mda")) $fsdbDumpMDA();
    $fsdbDumpvars(0,`LPA_SIM_TOP);
  end

  if ($test$plusargs("bin")) begin
    $value$plusargs("bin=%s", bin_file);
    init_mem(bin_file);
  end

  if ($test$plusargs("max-cycles")) begin
    $value$plusargs("max-cycles=%d", max_cycles);
    $display("set max cycles: %1d", max_cycles);
  end

  init_flash();

  #100 reset = 0;
  $display("Reset is released!");
end

always #1 clock <= ~clock;

SimTop sim(
  .clock(clock),
  .reset(reset),
  .io_logCtrl_log_begin(64'h0),
  .io_logCtrl_log_end(64'h0),
  .io_logCtrl_log_level(64'h0),
  .io_perfInfo_clean(1'b0),
  .io_perfInfo_dump(io_perfInfo_dump),
  .io_uart_out_valid(io_uart_out_valid),
  .io_uart_out_ch(io_uart_out_ch),
  .io_uart_in_valid(io_uart_in_valid),
  .io_uart_in_ch(8'hff)
);

always @(posedge clock) begin
  if (!reset && io_uart_out_valid) begin
    if(io_uart_out_ch[7] == 0) begin
      $fwrite(32'h8000_0001, "%c", io_uart_out_ch);
      $fflush();
    end else begin
      $display("\033[32mSIMULATION SUCCESSED!\033[0m");
    end
  end
  if(reset) begin
    io_perfInfo_dump <= 0;
  end else if(io_uart_out_valid & io_uart_out_ch[7]) begin
    io_perfInfo_dump <= 1;
  end else if(io_perfInfo_dump) begin
    io_perfInfo_dump <= 0;
    #1;
    time_end();
    flash_finish();
    mem_finish();
    $finish;
  end
end

always @(posedge clock) begin
  if(reset) begin
    cycles <= 0;
    time_start();
  end else begin 
    cycles <= cycles + 1'b1;
    cycle_add();
  end

  if(!reset && cycles >= max_cycles && max_cycles != 0) begin
    $display("Simutlation Timeout!");
    $finish;
  end
end

endmodule

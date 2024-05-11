#include "VSimTop.h"
#include "argparse.hpp"
#include "flash.h"
#include "ram.h"
#include <cstdio>
#include <string>

inline void step(VSimTop *mod) {
  mod->clock = 0;
  mod->eval();
  mod->clock = 1;
  mod->eval();
}

void do_reset(VSimTop *mod, int cycle) {
  int i = cycle;
  while (i-- > 0) {
    mod->reset = 1;
    step(mod);
  }
  mod->reset = 0;
}

bool do_uart(VSimTop *mod) {
  if (mod->io_uart_out_valid) {
    uint8_t code = mod->io_uart_out_ch;
    bool isEnd = (code & 0x80) != 0;
    char word = code & 0x7f;
    if (isEnd) {
      std::printf("\033[32mHIT GOOD TRAP!\033[0m");
    } else {
      std::printf("%c", word);
    }
    return isEnd;
  }
  return false;
}

int main(int argc, char *argv[]) {
  argparse::ArgumentParser argparser("Simulation", "1.0.0",
                                     argparse::default_arguments::help);

  argparser.add_argument("bin").help("Binary program");
  try {
    argparser.parse_args(argc, argv);
  } catch (const std::exception &err) {
    std::cerr << err.what() << std::endl;
    std::cerr << argparser;
    std::exit(1);
  }
  auto &&binStr = argparser.get<std::string>("bin");
  MmapMemory mem(binStr.c_str());
  simMemory = &mem;
  init_flash();

  auto top = std::make_unique<VSimTop>();
  top->io_perfInfo_dump = 0;
  top->io_uart_in_ch = 0;
  top->io_perfInfo_clean = 0;
  top->io_logCtrl_log_begin = 0;
  top->io_logCtrl_log_end = 0;
  top->io_logCtrl_log_level = 0;

  do_reset(top.get(), 128);

  while (true) {
    step(top.get());
    if (do_uart(top.get()))
      break;
  }

  top->io_perfInfo_dump = 1;
  step(top.get());
  top->final();

  return 0;
}
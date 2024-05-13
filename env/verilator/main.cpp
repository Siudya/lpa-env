#include "VSimTop.h"
#include "argparse.hpp"
#include "flash.h"
#include "ram.h"
#include <iostream>
#include <string>
#include <chrono>
using std::cout;
using std::flush;
using namespace std::chrono;

inline void step(VSimTop *mod)
{
  mod->clock = 0;
  mod->eval();
  mod->clock = 1;
  mod->eval();
}

void do_reset(VSimTop *mod, int cycle)
{
  int i = cycle;
  while (i-- > 0)
  {
    mod->reset = 1;
    step(mod);
  }
  mod->reset = 0;
}

bool do_uart(VSimTop *mod)
{
  if (mod->io_uart_out_valid)
  {
    uint8_t code = mod->io_uart_out_ch;
    bool isEnd = (code & 0x80) != 0;
    char word = code & 0x7f;
    if (isEnd)
    {
      std::cout << "\033[32mSIMULATION SUCCESSED!\033[0m" << std::endl;
    }
    else
    {
      std::cout << word << flush;
    }
    return isEnd;
  }
  return false;
}

int main(int argc, char *argv[])
{
  argparse::ArgumentParser argparser("Simulation", "1.0.0",
                                     argparse::default_arguments::help);

  argparser.add_argument("bin").help("Binary program");
  try
  {
    argparser.parse_args(argc, argv);
  }
  catch (const std::exception &err)
  {
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
  auto st = system_clock::now();
  uint64_t cycles = 0;
  while (true)
  {
    step(top.get());
    cycles ++;
    if (do_uart(top.get()))
      break;
  }
  auto et = system_clock::now();
  auto elapsedMs = duration_cast<milliseconds>(et - st).count();
  auto speed = double(cycles * 1000) / elapsedMs;
  top->io_perfInfo_dump = 1;
  step(top.get());
  top->final();
  flash_finish();
  std::cout << "Cycles: " << cycles << " Time elapsed: " << elapsedMs << "ms " << "Speed: " << speed << " ticks/s" << std::endl;
  return 0;
}
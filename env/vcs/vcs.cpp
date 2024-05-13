#include <iostream>
#include <string>
#include <chrono>
using namespace std::chrono;
using namespace std;

uint64_t cycles;
time_point<system_clock, duration<long, std::ratio<1, 1000000000UL> > > st;
extern "C" void time_start() {
  st = system_clock::now();
  cycles = 0;
}

extern "C" void cycle_add() {
  cycles++;
}

extern "C" void time_end() {
  auto et = system_clock::now();
  auto elapsedMs = duration_cast<milliseconds>(et - st).count();
  auto speed = double(cycles * 1000) / elapsedMs;
  std::cout << "Cycles: " << cycles << " Time elapsed: " << elapsedMs << "ms " << "Speed: " << speed << " ticks/s" << endl;
}
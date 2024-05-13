#include "flash.h"
#include "configs.h"
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <sys/mman.h>
uint64_t *flash_base;

extern "C" void flash_read(uint32_t addr, uint64_t *data) {
  if (!flash_base) {
    return;
  }
  // addr must be 8 bytes aligned first
  uint32_t aligned_addr = addr & ~(0x7);
  uint64_t rIdx = aligned_addr / sizeof(uint64_t);
  if (rIdx >= FLASH_SIZE / sizeof(uint64_t)) {
    printf("[warning] read addr %x is out of bound\n", addr);
    *data = 0;
  } else {
    *data = flash_base[rIdx];
  }
}

extern "C" void init_flash() {
  flash_base = (uint64_t *)mmap(NULL, FLASH_SIZE, PROT_READ | PROT_WRITE,
                                MAP_ANON | MAP_PRIVATE, -1, 0);
  if (flash_base == (uint64_t *)MAP_FAILED) {
    printf("Warning: Insufficient phisical memory for flash\n");
    exit(1);
  }

  /** no specified flash_path ,use defualt 3 instructions*/
  // addiw   t0,zero,1
  // slli    to,to,  0x1f
  // jr      t0
  flash_base[0] = 0x01f292930010029b;
  flash_base[1] = 0x00028067;
}

extern "C" void flash_finish() {
  munmap(flash_base, FLASH_SIZE);
  flash_base = NULL;
}
#include "ram.h"
#include "configs.h"
#include <cstdint>
#include <cstdio>
#include <iostream>
#include <sys/mman.h>

SimMemory *simMemory = nullptr;

FileReader::FileReader(const char *filename)
    : file(filename, std::ios::binary) {
  if (!file.is_open()) {
    std::cerr << "Cannot open '" << filename << "'\n";
    exit(1);
  }

  // Get the size of the file
  file.seekg(0, std::ios::end);
  file_size = file.tellg();
  file.seekg(0, std::ios::beg);
}

uint64_t FileReader::read_all(void *dest) {
  if (file_size > PMEM_SIZE) {
    std::cerr << "Error: File too large" << std::endl;
    exit(1);
  }
  file.read(static_cast<char *>(dest), file_size);
  return file_size;
}

MmapMemory::MmapMemory(const char *image) : SimMemory() {
  // initialize memory using Linux mmap
  ram = (uint64_t *)mmap(NULL, PMEM_SIZE, PROT_READ | PROT_WRITE,
                         MAP_ANON | MAP_PRIVATE, -1, 0);
  if (ram == (uint64_t *)MAP_FAILED) {
    printf("Error: Insufficient phisical memory\n");
    exit(1);
  }
  if (image == NULL) {
    img_size = 0;
    return;
  }

  printf("The image is %s\n", image);
  FileReader reader(image);
  img_size = reader.read_all(ram);
}

MmapMemory::~MmapMemory() { munmap(ram, PMEM_SIZE); }

extern "C" uint64_t difftest_ram_read(uint64_t rIdx) {
  if (!simMemory)
    return 0;
  rIdx %= PMEM_SIZE / sizeof(uint64_t);
  return simMemory->at(rIdx);
}

extern "C" void difftest_ram_write(uint64_t wIdx, uint64_t wdata,
                                   uint64_t wmask) {
  if (simMemory) {
    if (!simMemory->in_range_u64(wIdx)) {
      printf("ERROR: ram wIdx = 0x%lx out of bound!\n", wIdx);
      return;
    }
    simMemory->at(wIdx) = (simMemory->at(wIdx) & ~wmask) | (wdata & wmask);
  }
}

uint64_t pmem_read(uint64_t raddr) {
  if (raddr % sizeof(uint64_t)) {
    printf("Warning: pmem_read only supports 64-bit aligned memory access\n");
  }
  raddr -= PMEM_BASE;
  return difftest_ram_read(raddr / sizeof(uint64_t));
}

void pmem_write(uint64_t waddr, uint64_t wdata) {
  if (waddr % sizeof(uint64_t)) {
    printf("Warning: pmem_write only supports 64-bit aligned memory access\n");
  }
  waddr -= PMEM_BASE;
  return difftest_ram_write(waddr / sizeof(uint64_t), wdata, -1UL);
}

extern "C" void init_mem(const char *s) {
  simMemory = new MmapMemory(s);
}

extern "C" void mem_finish() {
  delete simMemory;
}
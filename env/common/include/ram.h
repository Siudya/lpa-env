#ifndef __RAM_H__
#define __RAM_H__

#include "configs.h"
#include <fstream>
#include <functional>

uint64_t pmem_read(uint64_t raddr);
void pmem_write(uint64_t waddr, uint64_t wdata);

extern "C" void init_mem(const char *s);
extern "C" void mem_finish();

class FileReader {
public:
  FileReader(const char *filename);
  ~FileReader() { file.close(); }
  uint64_t len() { return file_size; };
  uint64_t read_all(void *dest);

private:
  std::ifstream file;
  uint64_t file_size;
};

class SimMemory {
public:
  SimMemory() = default;
  bool in_range_u64(uint64_t index) {
    return index < PMEM_SIZE / sizeof(uint64_t);
  }
  virtual uint64_t &at(uint64_t index) = 0;
  virtual ~SimMemory() = default;
};

extern SimMemory *simMemory;

class MmapMemory : public SimMemory {
private:
  uint64_t *ram;
  uint64_t img_size;

public:
  MmapMemory(const char *image);
  ~MmapMemory();
  uint64_t &at(uint64_t index) { return ram[index]; }
  uint64_t *as_ptr() { return ram; }
  uint64_t get_img_size() { return img_size; }
};

#endif
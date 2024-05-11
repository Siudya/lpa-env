

EMU = $(COMP_DIR)/emu
EMU_MK = $(COMP_DIR)/V$(VTOP).mk

CSRC_DIR = $(abspath env/common/src)
CXXFILES = $(shell find $(CSRC_DIR) -name "*.cpp")

EMU_SRC_DIR = $(abspath env/verilator)
CXXFILES += $(shell find $(EMU_SRC_DIR) -name "*.cpp")

INCLUDE_DIR = $(abspath env/common/include)
HEADERS = $(shell find $(INCLUDE_DIR) -name "*[.h|.hpp]")

VERILATOR_FLAGS = --cc --exe -O3 --top-module $(VTOP)
VERILATOR_FLAGS += --no-timing --threads $(THREADS) --threads-dpi all
VERILATOR_FLAGS += -Wno-UNOPTTHREADS -Wno-STMTDLY -Wno-WIDTH -I$(INCLUDE_DIR)
VERILATOR_FLAGS += +define+ASSERT_VERBOSE_COND_=0 +define+STOP_COND_=0
VERILATOR_FLAGS += +define+LPA_SIM_TOP=SimTop.l_soc.core_with_l2.core.ctrlBlock.intDq
VERILATOR_FLAGS += $(CXXFILES) -f $(FILELIST) -o $(abspath $(EMU)) -Mdir $(COMP_DIR)
VERILATOR_FLAGS += -CFLAGS -std=c++17

$(EMU_MK): $(HEADERS) $(CXXFILES)
	verilator $(VERILATOR_FLAGS) 

$(EMU):$(EMU_MK)
	$(MAKE)  VM_PARALLEL_BUILDS=1 OPT_FAST="-O3" -C $(COMP_DIR) -f $(EMU_MK)

emu:$(EMU)

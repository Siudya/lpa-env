

EMU = $(COMP_DIR)/emu
EMU_MK = $(COMP_DIR)/V$(VTOP).mk

CSRC_DIR = $(abspath env/common/src)
CXXFILES = $(shell find $(CSRC_DIR) -name "*.cpp")

EMU_SRC_DIR = $(abspath env/common/verilator)
CXXFILES += $(shell find $(EMU_SRC_DIR) -name "*.cpp")

INCLUDE_DIR = $(abspath env/common/include)
HEADERS = $(shell find $(INCLUDE_DIR) -name "*.h")

VERILATOR_FLAGS = --cc --exe -O3 --top-module $(VTOP)
VERILATOR_FLAGS += --no-timing --threads $(THREADS) --threads-dpi all
VERILATOR_FLAGS += -Wno-UNOPTTHREADS -Wno-STMTDLY -Wno-WIDTH
VERILATOR_FLAGS += -CFLAGS -std=c++17 -I$(INCLUDE_DIR)
VERILATOR_FLAGS += +define+ASSERT_VERBOSE_COND_=0 +define+STOP_COND_=0 +define+SYNTHESIS
VERILATOR_FLAGS += +define+LPA_SIM_TOP=SimTop.l_soc.core_with_l2.core.ctrlBlock.intDq
VERILATOR_FLAGS += -CFLAGS -std=c++17 -I$(INCLUDE_DIR)
VERILATOR_FLAGS += $(CXXFILES) -f $(FILELIST) -o $(abspath $(EMU)) -Mdir $(COMP_DIR)

$(EMU_MK):$(FILELIST) $(HEADERS) $(CXXFILES)
	verilator $(VERILATOR_FLAGS) 

$(EMU):$(EMU_MK)
	$(MAKE) -s VM_PARALLEL_BUILDS=1 OPT_FAST="-O3" -C $(EMU_MK)

emu:$(EMU)

EMU = $(COMP_DIR)/emu
EMU_MK = $(COMP_DIR)/V$(VTOP).mk

CSRC_DIR = $(abspath env/common/src)
CXXFILES = $(shell find $(CSRC_DIR) -name "*.cpp")

EMU_SRC_DIR = $(abspath env/verilator)
CXXFILES += $(shell find $(EMU_SRC_DIR) -name "*.cpp")

INCLUDE_DIR = $(abspath env/common/include)
HEADERS = $(shell find $(INCLUDE_DIR) -name "*.h" -or -name "*.hpp")

CFLAGS = -std=c++17 -I$(INCLUDE_DIR) -I$(COMP_DIR)
LDFLAGS = -lrt -lpthread

VERILATOR_FLAGS = --cc --exe -O3 --top-module $(VTOP)
VERILATOR_FLAGS += --no-timing --threads $(THREADS) --threads-dpi all
VERILATOR_FLAGS += +define+ASSERT_VERBOSE_COND_=0 +define+STOP_COND_=0 +define+VERILATOR_5016
VERILATOR_FLAGS += +define+LPA_SIM_TOP=SimTop.$(LPA_SIM_TOP)
VERILATOR_FLAGS += -Wno-UNOPTTHREADS -Wno-STMTDLY -Wno-WIDTH
VERILATOR_FLAGS += -CFLAGS "$(CFLAGS)"
VERILATOR_FLAGS += -LDFLAGS "$(LDFLAGS)"
VERILATOR_FLAGS += -o $(abspath $(EMU)) -Mdir $(COMP_DIR)
VERILATOR_FLAGS += $(CXXFILES) -f $(FILELIST)

$(EMU_MK): 
	verilator $(VERILATOR_FLAGS) 

$(EMU):$(EMU_MK) $(CXXFILES) $(HEADERS)
	$(MAKE) -s VM_PARALLEL_BUILDS=1 OPT_FAST="-O3" -C $(COMP_DIR) -f $(EMU_MK)

emu:$(EMU)

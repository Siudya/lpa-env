CSRC_DIR = $(abspath env/common/src)
CXXFILES = $(shell find $(CSRC_DIR) -name "*.c" -or -name "*.cpp")

SIMV_SRC_DIR = $(abspath env/vcs)
CXXFILES += $(shell find $(SIMV_SRC_DIR) -name "*.c" -or -name "*.cpp")

INCLUDE_DIR = $(abspath env/common/include)

VCS_CXXFLAGS = -std=c++11 -static -Wall -I$(INCLUDE_DIR)

ifndef VERDI_HOME
$(error VERDI_HOME is not set. Try whereis verdi, abandon /bin/verdi and set VERID_HOME manually)
else
NOVAS_HOME = $(VERDI_HOME)
NOVAS = $(NOVAS_HOME)/share/PLI/VCS/LINUX64
EXTRA += -P $(NOVAS)/novas.tab $(NOVAS)/pli.a
endif

SIM_FILELIST = $(COMP_DIR)/sim.f
SIMV = $(COMP_DIR)/simv

VCS_FLAGS += -full64 +v2k -timescale=1ns/1ns -sverilog +warn=noTFIPC -l comp.log -top tb_top
VCS_FLAGS += -fgp -kdb +nospecify +notimingcheck +vcs+initreg+random -assert enable_hier
VCS_FLAGS += +define+ASSERT_VERBOSE_COND_=0 +define+STOP_COND_=0
VCS_FLAGS += +define+VCS +define+LPA_SIM_TOP=tb_top.sim.$(LPA_SIM_TOP)
VCS_FLAGS += -CFLAGS "$(VCS_CXXFLAGS)" -j200 $(EXTRA)

$(SIM_FILELIST):
	@find $(SIMV_SRC_DIR) -name "*.sv" -or -name "*.v" > $(SIM_FILELIST)
	@echo "-f $(FILELIST)" >> $(SIM_FILELIST)
	
$(SIMV):$(SIM_FILELIST)
	cd $(COMP_DIR) && vcs $(VCS_FLAGS) -f $(SIM_FILELIST) $(CXXFILES)

simv:$(SIMV)

.PHONY: $(SIM_FILELIST)
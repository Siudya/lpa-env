SIM_DIR = $(abspath sim)
BIN_DIR = $(abspath bin)
BIN ?= drystone
THREADS ?= 8

VERILATOR_SIM_DIR = $(SIM_DIR)/verilator
VCS_SIM_DIR = $(SIM_DIR)/vcs
VERILATOR_COMD_DIR = $(VERILATOR_SIM_DIR)/comp
VCS_COMD_DIR = $(VCS_SIM_DIR)/comp
VERILATOR_RUN_DIR = $(VERILATOR_SIM_DIR)/$(BIN)
VCS_RUN_DIR = $(VCS_SIM_DIR)/$(BIN)
FILELIST = $(abspath dut)/flist.f
 
emu:$(FLIST)
	mkdir -p $(VERILATOR_COMD_DIR)
	$(MAKE) -f verilator.mk emu FILELIST=$(FILELIST) COMP_DIR=$(VERILATOR_COMD_DIR) VTOP=SimTop THREADS=$(THREADS)

simv:
	mkdir -p $(VCS_COMD_DIR)

emu-run: emu
	$(shell if [ ! -e $(VERILATOR_RUN_DIR) ];then mkdir -p $(VERILATOR_RUN_DIR); fi)
	$(shell if [ -e $(VERILATOR_RUN_DIR)/emu ];then rm -f $(VERILATOR_RUN_DIR)/emu; fi)
	ln -s $(VERILATOR_COMD_DIR)/emu $(VERILATOR_RUN_DIR)/emu
	cd $(VERILATOR_RUN_DIR) && (./emu $(BIN_DIR)/$(BIN).bin 2> assert.log | tee sim.log)

simv-run: simv
	$(shell if [ ! -e $(VCS_RUN_DIR) ];then mkdir -p $(VCS_RUN_DIR); fi)
	$(shell if [ -e $(VCS_RUN_DIR)/simv ];then rm -f $(VCS_RUN_DIR)/simv; fi)
	$(shell if [ -e $(VCS_RUN_DIR)/simv.daidir ];then rm -rf $(VCS_RUN_DIR)/simv.daidir; fi)
	ln -s $(VCS_COMD_DIR)/simv $(VCS_RUN_DIR)/simv
	ln -s $(VCS_COMD_DIR)/simv.daidir $(VCS_RUN_DIR)/simv.daidir
	cd $(VCS_RUN_DIR) && (./simv $(RUN_OPTS) 2> assert.log | tee sim.log)

verdi:
	cd $(VCS_RUN_DIR) && verdi -sv -2001 +verilog2001ext+v +systemverilogext+v -ssf tb_top.vf -dbdir simv.daidir

clean:
	@rm -rf $(VERILATOR_COMD_DIR)
	@rm -rf $(VCS_COMD_DIR)

.PHONY:clean
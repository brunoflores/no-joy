TOP_FILE = ./src/Tb.bsv
MORE_SOURCES = ./src/Proc1Cyc.bsv ./src/Decode.bsv ./src/Exec.bsv ./src/ProcTypes.bsv ./src/RFile.bsv ./src/IMemory.bsv ./src/DMemory.bsv ./src/Cop.bsv
TOP_MODULE = mkTb
EXE = Tb

# ----- 8< ---------

BSC_COMP_FLAGS = -keep-fires -aggressive-conditions -check-assert -cpp -show-range-conflict

BSC_LINK_FLAGS = -keep-fires

BSC_PATHS = -p ./src:+

B_SIM_DIR = build
B_SIM_DIRS = -simdir $(B_SIM_DIR) -bdir $(B_SIM_DIR) -info-dir $(B_SIM_DIR)

BOS = $(foreach s,$(SOURCES),$(B_SIM_DIR)/$(s:.bsv=.bo))

# $(B_SIM_DIR)/$(subst .bsv,.bo,$(SOURCES)) $(B_SIM_DIR)/$(TOP_MODULE).ba: $(SOURCES)
$(BOS) $(B_SIM_DIR)/$(TOP_MODULE).ba: $(TOP_FILE) $(MORE_SOURCES)
	mkdir  -p $(B_SIM_DIR)
	@echo Compiling for Bluesim ...
	bsc -u -sim $(B_SIM_DIRS) $(BSC_COMP_FLAGS) $(BSC_PATHS) $(TOP_FILE)
	@echo Compiling for Bluesim finished

# $(EXE).so: $(B_SIM_DIR)/$(subst .bsv,.bo,$(SOURCES)) $(B_SIM_DIR)/$(TOP_MODULE).ba
$(EXE).so: $(BOS) $(B_SIM_DIR)/$(TOP_MODULE).ba
	@echo Linking for Bluesim ...
	bsc -e $(TOP_MODULE) -sim -o $(EXE) $(B_SIM_DIRS) $(BSC_LINK_FLAGS) $(BSC_PATHS)
	@echo Linking for Bluesim finished

$(EXE): $(EXE).so

.PHONY: clean
clean:
	rm -rf $(EXE) $(EXE).so $(B_SIM_DIR)

# .PHONY: b_all
# b_all: b_compile b_link b_sim
#
# .PHONY: b_compile
# b_compile:
# 	mkdir  -p build_b_sim
# 	@echo Compiling for Bluesim ...
# 	bsc -u -sim $(B_SIM_DIRS) $(BSC_COMP_FLAGS) $(BSC_PATHS) $(SOURCES)
# 	@echo Compiling for Bluesim finished
#
# .PHONY: b_link
# b_link: b_compile
# 	@echo Linking for Bluesim ...
# 	bsc -e $(TOP_MODULE) -sim -o $(B_SIM_EXE) $(B_SIM_DIRS) $(BSC_LINK_FLAGS) $(BSC_PATHS)
# 	@echo Linking for Bluesim finished
#
# .PHONY: b_sim
# b_sim: b_link
# 	@echo Bluesim simulation ...
# 	./$(B_SIM_EXE)
# 	@echo Bluesim simulation finished
#
# .PHONY: b_sim_vcd
# b_sim_vcd: b_link
# 	@echo Bluesim simulation and dumping VCD in dump.vcd ...
# 	./$(B_SIM_EXE) -V
# 	@echo Bluesim simulation and dumping VCD in dump.vcd finished

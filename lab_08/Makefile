# ============================================================
#  Makefile  -  router lab simulation (Synopsys VCS)
#
#  Project layout (all files in this directory):
#      router.v             DUT
#      router_cstr_pkg.sv   testbench package (rt_multi_pkg)
#      tb08.sv             testbench top (module tb)
#
#  Usage:
#      make build   # compile  -> ./simv
#      make run     # batch run
#      make gui     # run with GUI  (./simv -gui &)
#      make clean   # remove generated files
# ============================================================

# ---- design / testbench files ----
RTL   := router.v
PKG   := router_cstr_pkg.sv
TB    := tb08.sv
SRCS  := $(RTL) $(PKG) $(TB)
TOP   := tb
SEED   := 12345
TESTNAME ?= single_ch_test
# ---- tools ----
VCS   := vcs
SIMV  := simv

# ---- options ----
VCS_FLAGS := -full64 -debug_access+all -sverilog -timescale=1ns/1ps
SIM_FLAGS := -l simv.log -sml +ntb_random_seed=${SEED} +TESTNAME=${TESTNAME}

# ---- generated files (removed by `make clean`) ----
GEN := $(SIMV) csrc $(SIMV).daidir ucli.key \
       *.log *.vpd *.fsdb *.vcd DVEfiles verdiLog novas.*

.PHONY: all build run gui verdi clean help

# default target
all: build

# ---- compile ----
build: $(SIMV)

$(SIMV): $(SRCS) Makefile
	$(VCS) $(VCS_FLAGS) $(SRCS) -top $(TOP) -l compile.log

# ---- batch run ----
run: build
	./$(SIMV) $(SIM_FLAGS)

# ---- GUI run (DVE) ----
gui: build
	./$(SIMV) $(SIM_FLAGS) -gui &

# ---- waveform with Verdi (optional) ----
verdi: build
	./$(SIMV) $(SIM_FLAGS) -gui=verdi &

# ---- cleanup ----
clean:
	rm -rf $(GEN)

# ---- help ----
help:
	@echo "targets:"
	@echo "  build   compile with VCS -> ./simv"
	@echo "  run     batch simulation"
	@echo "  gui     simulation with GUI (./simv -gui &)"
	@echo "  verdi   simulation with Verdi GUI"
	@echo "  clean   remove generated files"

# ============================================================
#  Makefile  -  router lab simulation (Synopsys VCS)
#
#  Project layout (all files in this directory):
#      router.v             DUT
#      router_test_pkg.sv   testbench package (rt_test_pkg)
#      tb05r.sv             testbench top (module tb)
#
#  Usage:
#      make build   # compile  -> ./simv
#      make run     # batch run
#      make gui     # run with GUI  (./simv -gui &)
#      make clean   # remove generated files
# ============================================================

# ---- design / testbench files ----
RTL   := router.v
PKG   := router_test_pkg.sv
TB    := tb05r.sv
SRCS  := $(RTL) $(PKG) $(TB)
TOP   := tb

# ---- tools ----
VCS   := vcs
SIMV  := simv

# ---- options ----
VCS_FLAGS := -full64 -debug_access+all -sverilog -timescale=1ns/1ps
SIM_FLAGS := -l simv.log

# ---- generated files (removed by `make clean`) ----
GEN := $(SIMV) csrc $(SIMV).daidir ucli.key \
       *.log *.vpd *.fsdb *.vcd DVEfiles verdiLog novas.*

.PHONY: all build run gui verdi clean help

# default target
all: build

# ---- compile ----
build: $(SIMV)

$(SIMV): $(SRCS)
	$(VCS) $(VCS_FLAGS) $(SRCS) -top $(TOP) -l compile.log

# ---- batch run ----
run: build
	./$(SIMV) $(SIM_FLAGS)

# ---- GUI run (DVE) ----
gui: build
	./$(SIMV) -gui &

# ---- waveform with Verdi (optional) ----
verdi: build
	./$(SIMV) -gui=verdi &

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

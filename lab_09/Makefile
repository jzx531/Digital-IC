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
#      make comp    # run coverage and generate a report
#      make urgcov  # merge all cov_*.vdb databases
#      make gui     # run with GUI  (./simv -gui &)
#      make clean   # remove generated files
# ============================================================

# ---- design / testbench files ----
RTL   := router.v
PKG   := router_cstr_pkg.sv
TB    := tb09.sv
SRCS  := $(RTL) $(PKG) $(TB)
TOP   := tb
SEED   := 12345
TESTNAME ?= single_ch_test
# ---- tools ----
VCS   := vcs
SIMV  := simv
URG   := urg
DVE   := dve
HTML_VIEWER ?= firefox

# ---- coverage ----
COV_SIMV    := simv_cov
COV_CSRCDIR := csrc_cov
COV_METRICS := line+cond+fsm+tgl+branch+assert
COV_DIR     := cov_$(TESTNAME)_$(SEED).vdb
COV_REPORT  := coverage_report_$(TESTNAME)_$(SEED)
COV_DATABASES       = $(wildcard cov_*.vdb)
MERGED_COV_NAME     ?= merged_coverage
MERGED_COV_REPORT   ?= coverage_report_merged
VIEW                  ?= none

# ---- options ----
VCS_FLAGS := -full64 -debug_access+all -sverilog -timescale=1ns/1ps
SIM_FLAGS := -l simv.log -sml +ntb_random_seed=${SEED} +TESTNAME=${TESTNAME} -cm line+tgl+branch -cm_name $(TESTNAME)_$(SEED)
                

# ---- generated files (removed by `make clean`) ----
GEN := $(SIMV) csrc $(SIMV).daidir ucli.key \
       $(COV_SIMV) $(COV_CSRCDIR) $(COV_SIMV).daidir \
       *.vdb coverage_report_* *.log *.vpd *.fsdb *.vcd \
       DVEfiles verdiLog novas.*

.PHONY: all build run comp urgcov gui verdi clean help

# default target
all: build

# ---- compile ----
build: $(SIMV)

$(SIMV): $(SRCS) Makefile
	$(VCS) $(VCS_FLAGS) $(SRCS) -top $(TOP) -l compile.log

# ---- batch run ----
run: build
	./$(SIMV) $(SIM_FLAGS)

# ---- compile, run, and report coverage ----
comp:
	$(VCS) $(VCS_FLAGS) -cm $(COV_METRICS) -cm_dir $(COV_DIR) \
		-Mdir=$(COV_CSRCDIR) $(SRCS) -top $(TOP) \
		-o $(COV_SIMV) -l compile_cov.log
	./$(COV_SIMV) -l simv_cov.log -sml \
		+ntb_random_seed=$(SEED) +TESTNAME=$(TESTNAME) \
		-cm $(COV_METRICS) -cm_dir $(COV_DIR)
	$(URG) -dir $(COV_DIR) -format both -report $(COV_REPORT)
	@echo "Coverage report: $(COV_REPORT)/dashboard.html"

# ---- merge coverage databases from multiple test runs ----
urgcov:
	@if [ -z "$(strip $(COV_DATABASES))" ]; then \
		echo "Error: no cov_*.vdb coverage databases found"; \
		echo "Run 'make comp TESTNAME=<test> SEED=<seed>' first"; \
		exit 1; \
	fi
	$(URG) -dir $(COV_DATABASES) -dbname $(MERGED_COV_NAME) \
		-format both -report $(MERGED_COV_REPORT)
	@echo "Merged database: $(MERGED_COV_NAME).vdb"
	@echo "Merged report: $(MERGED_COV_REPORT)/dashboard.html"
	@case "$(VIEW)" in \
		none) \
			echo "View with DVE:  make urgcov VIEW=dve"; \
			echo "View as HTML:  make urgcov VIEW=html"; \
			echo "Open both:     make urgcov VIEW=both";; \
		dve) \
			$(DVE) -full64 -cov -covdir $(MERGED_COV_NAME).vdb &;; \
		html) \
			$(HTML_VIEWER) $(MERGED_COV_REPORT)/dashboard.html &;; \
		both) \
			$(DVE) -full64 -cov -covdir $(MERGED_COV_NAME).vdb & \
			$(HTML_VIEWER) $(MERGED_COV_REPORT)/dashboard.html &;; \
		*) \
			echo "Error: VIEW must be none, dve, html, or both"; \
			exit 1;; \
	esac

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
	@echo "  comp    run coverage and generate HTML/text reports"
	@echo "  urgcov  merge coverage; optionally set VIEW=dve|html|both"
	@echo "  gui     simulation with GUI (./simv -gui &)"
	@echo "  verdi   simulation with Verdi GUI"
	@echo "  clean   remove generated files"

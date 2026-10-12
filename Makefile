SHELL := /bin/bash

VIVADO_SETTINGS ?= /home/lenovo/tools/AMDDesignTools/2025.2/Vivado/settings64.sh
TOP_MODULE      ?= fifo_tb_top
SNAPSHOT        ?= fifo_sim_snap
SEED            ?= random

.PHONY: help compile elaborate sim wave regression cov_report clean

help:
	@echo "Synchronous FIFO verification mini-project"
	@echo ""
	@echo "  compile      Compile SystemVerilog sources using xvlog into out/"
	@echo "  elaborate    Create simulation snapshot with code coverage (-cc_type sbct)"
	@echo "  sim          Run simulation using xsim (batch mode, supports SEED=<val>)"
	@echo "  wave         Open simulation GUI with Vivado waveform viewer"
	@echo "  regression   Run automated multi-seed regression suite (20 seeds)"
	@echo "  cov_report   View text summary of coverage reports"
	@echo "  clean        Remove all generated artifacts in out/ and root"

compile:
	mkdir -p out
	source $(VIVADO_SETTINGS) && xvlog -sv -f filelists/tb.f -log out/xvlog.log
	@rm -f xvlog.pb

elaborate: compile
	source $(VIVADO_SETTINGS) && xelab $(TOP_MODULE) -s $(SNAPSHOT) -cc_type sbct --cov_db_dir out --timescale 1ns/1ps -log out/xelab.log
	@rm -f xelab.pb

sim: elaborate
	source $(VIVADO_SETTINGS) && xsim $(SNAPSHOT) --sv_seed $(SEED) --runall --cov_db_dir out -log out/xsim.log -wdb out/$(SNAPSHOT).wdb
	@rm -f xsim*.jou xsim*.backup.jou

wave: elaborate
	source $(VIVADO_SETTINGS) && xsim $(SNAPSHOT) --gui

regression: elaborate
	mkdir -p out/runs
	VIVADO_SETTINGS=$(VIVADO_SETTINGS) python3 scripts/regression.py

cov_report:
	@echo "Coverage reports located in out/fcov_rpt/:"
	@echo "  Functional Coverage Dashboard : out/fcov_rpt/functionalCoverageReport/dashboard.html"
	@echo "  Code Coverage Dashboard       : out/fcov_rpt/codeCoverageReport/dashboard.html"

clean:
	rm -rf out reports xsim.dir .Xil *.log *.pb *.jou *.wdb dump.vcd runs xsim.covdb xsim.codeCov
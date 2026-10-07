SHELL := /bin/bash

VIVADO_SETTINGS ?= /home/lenovo/tools/AMDDesignTools/2025.2/Vivado/settings64.sh
TOP_MODULE      ?= fifo_tb_top
SNAPSHOT        ?= fifo_sim_snap
SEED            ?= random

.PHONY: help compile elaborate sim wave regression clean

help:
	@echo "Synchronous FIFO verification mini-project"
	@echo ""
	@echo "  compile      Compile SystemVerilog sources using xvlog"
	@echo "  elaborate    Create simulation snapshot using xelab"
	@echo "  sim          Run simulation using xsim (batch mode, supports SEED=<val>)"
	@echo "  wave         Open simulation GUI with Vivado waveform viewer"
	@echo "  regression   Run automated multi-seed regression suite using Python"
	@echo "  clean        Remove generated artifacts"

compile:
	source $(VIVADO_SETTINGS) && xvlog -sv -f filelists/tb.f

elaborate: compile
	source $(VIVADO_SETTINGS) && xelab $(TOP_MODULE) -s $(SNAPSHOT) --timescale 1ns/1ps

sim: elaborate
	source $(VIVADO_SETTINGS) && xsim $(SNAPSHOT) --sv_seed $(SEED) --runall

wave: elaborate
	source $(VIVADO_SETTINGS) && xsim $(SNAPSHOT) --gui

regression: elaborate
	python3 scripts/regression.py

clean:
	rm -rf xsim.dir .Xil *.log *.pb *.jou *.wdb dump.vcd runs
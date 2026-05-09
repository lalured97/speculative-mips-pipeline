# =============================================================================
# Makefile — Speculative MIPS Pipeline Simulation
# Tools: iverilog (simulation) + GTKWave (waveform viewer)
# =============================================================================

# Tool paths (update if needed)
IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave

# Source files
RTL_DIR = rtl
TB_DIR  = tb
SIM_DIR = sim

RTL_SRCS = $(RTL_DIR)/branch_predictor.sv  \
           $(RTL_DIR)/pc_control.sv         \
           $(RTL_DIR)/flush_control.sv      \
           $(RTL_DIR)/performance_counter.sv \
           $(RTL_DIR)/mips_pipeline.sv

TB_SRC   = $(TB_DIR)/tb_mips_pipeline.sv

SIM_OUT  = $(SIM_DIR)/sim_out
VCD_FILE = $(SIM_DIR)/waves.vcd
SAIF_FILE = $(SIM_DIR)/saif.saif

# GTKWave config (optional, auto-generated)
WAVE_CFG = $(SIM_DIR)/waves.gtkw

# =============================================================================
# TARGETS
# =============================================================================

.PHONY: all compile sim waves clean help

all: compile sim

compile:
	@mkdir -p $(SIM_DIR)
	@echo "► Compiling SystemVerilog files..."
	$(IVERILOG) -g2012 -Wall \
		-o $(SIM_OUT) \
		$(RTL_SRCS) $(TB_SRC)
	@echo "✓ Compilation successful"

sim: compile
	@echo "► Running simulation..."
	$(VVP) $(SIM_OUT)
	@echo "✓ Simulation complete — VCD: $(VCD_FILE)"

waves: sim
	@echo "► Opening GTKWave..."
	@if [ -f $(WAVE_CFG) ]; then \
		$(GTKWAVE) $(VCD_FILE) $(WAVE_CFG); \
	else \
		$(GTKWAVE) $(VCD_FILE); \
	fi

# Generate a GTKWave save file with useful signals pre-loaded
gtkwave-config:
	@mkdir -p $(SIM_DIR)
	@cat > $(WAVE_CFG) << 'EOF'
[dumpfile] "sim/waves.vcd"
[savefile] "sim/waves.gtkw"
[size] 1400 800
[zoom] -22.0
[signals]
tb_mips_pipeline.clk
tb_mips_pipeline.rst_n
-
[comment] === PC Tracking ===
tb_mips_pipeline.dbg_pc_fetch[31:0]
tb_mips_pipeline.dbg_pc_ex[31:0]
-
[comment] === Branch Prediction ===
tb_mips_pipeline.dbg_pred_taken
tb_mips_pipeline.dbg_mispredicted
tb_mips_pipeline.dbg_flushing
-
[comment] === Performance Counters ===
tb_mips_pipeline.perf_total_branches[15:0]
tb_mips_pipeline.perf_correct_pred[15:0]
tb_mips_pipeline.perf_mispredictions[15:0]
tb_mips_pipeline.perf_flush_cycles[15:0]
tb_mips_pipeline.perf_accuracy[6:0]
EOF
	@echo "✓ GTKWave config written to $(WAVE_CFG)"

clean:
	@rm -rf $(SIM_DIR)/*.vcd $(SIM_DIR)/sim_out
	@echo "✓ Cleaned simulation outputs"

help:
	@echo "Speculative MIPS Pipeline — Build Targets:"
	@echo "  make          — compile + simulate"
	@echo "  make compile  — compile only"
	@echo "  make sim      — compile + run simulation"
	@echo "  make waves    — run sim + open GTKWave"
	@echo "  make clean    — remove generated files"

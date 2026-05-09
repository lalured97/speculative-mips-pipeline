# Speculative Execution with Branch Prediction and Pipeline Recovery

## Overview

This project implements a simplified speculative execution framework on top of a pipelined MIPS-style processor using SystemVerilog.

The design demonstrates how modern processors improve performance by predicting branch outcomes before they are resolved, allowing instruction fetch to continue speculatively. When a branch prediction is incorrect, the processor detects the misprediction and flushes incorrect instructions from the pipeline.

The implementation focuses on educational clarity and architectural concepts rather than full industrial-level processor complexity.

---

# Project Features

## Implemented Features

* Program Counter (PC)
* Instruction Fetch Logic
* Instruction Memory
* Simplified Register File
* IF/ID and ID/EX Pipeline Registers
* 2-bit Saturating Counter Branch Predictor
* Speculative Instruction Fetch
* Branch Resolution Logic
* Pipeline Flush Recovery Mechanism
* Hardware Performance Counters
* GTKWave Visualization Support

---

# Processor Architecture

The processor follows a simplified pipelined execution model.

## Pipeline Stages

### IF — Instruction Fetch

* Fetches instruction from instruction memory.
* Branch predictor determines speculative control flow.
* Computes next PC.

### ID — Instruction Decode

* Decodes opcode and register fields.
* Reads register values.
* Stores instruction into pipeline registers.

### EX — Execute / Branch Resolution

* Evaluates branch conditions.
* Determines actual branch outcome.
* Detects branch mispredictions.

### Recovery Stage

* Flushes wrong-path instructions after misprediction.
* Corrects PC to proper target address.

---

# Branch Prediction Design

The branch predictor uses a:

## 2-bit Saturating Counter Predictor

Each branch entry stores a 2-bit prediction state.

### Predictor States

| State | Meaning            |
| ----- | ------------------ |
| 00    | Strongly Not Taken |
| 01    | Weakly Not Taken   |
| 10    | Weakly Taken       |
| 11    | Strongly Taken     |

The predictor updates dynamically depending on actual branch outcomes.

---

# Speculative Execution

The processor speculatively fetches future instructions before branch outcomes are fully resolved.

## Speculative Flow

1. Predictor predicts branch direction.
2. Processor fetches instructions along predicted path.
3. Branch resolves later in pipeline.
4. Prediction is compared against actual outcome.
5. If incorrect:

   * Flush signal activates.
   * Wrong instructions are squashed.
   * PC is redirected.

---

# Pipeline Recovery

When a branch misprediction occurs:

* `mispredict` signal becomes active.
* `flush` signal clears wrong-path instructions.
* PC is corrected to the actual branch target.

This demonstrates speculative execution recovery behavior used in modern processors.

---

# Performance Counters

The design includes hardware counters for monitoring branch behavior.

## Counters Implemented

| Counter        | Purpose                             |
| -------------- | ----------------------------------- |
| total_branches | Counts executed branch instructions |
| mispredictions | Counts incorrect predictions        |
| flush_cycles   | Counts recovery flush events        |

These counters help evaluate predictor performance.

---

# Test Program

The instruction memory contains a small test program:

* ADDI instructions initialize registers.
* BEQ instruction triggers branch prediction.
* Wrong-path instructions demonstrate speculative fetch.
* Correct target instruction demonstrates recovery.

---

# Waveform Demonstration

GTKWave was used to verify processor behavior.

## Important Signals

| Signal         | Description             |
| -------------- | ----------------------- |
| pc             | Current Program Counter |
| next_pc        | Next Program Counter    |
| instr          | Current Instruction     |
| pred_taken     | Branch Predictor Output |
| actual_taken   | Actual Branch Result    |
| mispredict     | Misprediction Detection |
| flush          | Pipeline Flush Signal   |
| total_branches | Branch Counter          |
| mispredictions | Misprediction Counter   |
| flush_cycles   | Flush Counter           |

---

# Example Execution Behavior

During simulation:

* The predictor initially predicts incorrectly.
* Branch resolves as taken.
* `mispredict` becomes HIGH.
* `flush` activates.
* Wrong instructions are removed.
* PC recovers to correct target.
* Performance counters increment.

This demonstrates speculative execution and recovery behavior.

---

# Files

## RTL Files

| File                | Description                   |
| ------------------- | ----------------------------- |
| mips_pipeline.sv    | Main processor implementation |
| tb_mips_pipeline.sv | Testbench                     |

---

# Simulation Instructions

## Compile

```bash
iverilog -g2012 -o sim.out mips_pipeline.sv tb_mips_pipeline.sv
```

## Run Simulation

```bash
vvp sim.out
```

## Open GTKWave

```bash
gtkwave wave.vcd
```

---

# Learning Outcomes

This project helped demonstrate:

* Pipelined processor behavior
* Branch prediction concepts
* Speculative execution
* Pipeline recovery mechanisms
* Hardware performance monitoring
* RTL design using SystemVerilog
* Simulation and waveform debugging using GTKWave

---

# Conclusion

This project successfully demonstrates a simplified speculative execution processor with branch prediction and pipeline recovery.

The implementation captures the core architectural ideas used in modern processors:

* speculative instruction execution
* dynamic branch prediction
* misprediction recovery
* performance monitoring

Although simplified for educational purposes, the design provides practical insight into how modern pipelined CPUs improve performance through speculation.


## 8. Viva Preparation

### Q: What is speculative execution?
**A:** "When a branch is encountered, instead of stalling and waiting for the
branch to resolve, we *predict* the outcome and continue fetching and executing
instructions along the predicted path. If the prediction is correct, we gain
performance. If wrong, we *flush* the speculatively executed instructions and
restart from the correct path."

### Q: What is a 2-bit predictor and why is it better than 1-bit?
**A:** "A 2-bit predictor uses a saturating counter with 4 states: Strongly
Taken, Weakly Taken, Weakly Not Taken, Strongly Not Taken. Two mispredictions
are needed before the prediction *flips*. This handles loops much better than
1-bit — a loop's exit branch won't corrupt the predictor for the next iteration."

### Q: What is pipeline flush and how do you implement it?
**A:** "When a misprediction is detected in the EX stage, we inject NOP bubbles
into the IF/ID and ID/EX pipeline registers over 2 cycles. This effectively
*squashes* the wrong-path instructions before they reach the write-back stage
and modify the architectural state."

### Q: What is the misprediction penalty?
**A:** "In our 5-stage pipeline, a misprediction costs 2 cycles — the latency
between when the wrong-path instruction was fetched and when the flush completes.
Our performance counter tracks these cycles, giving us a quantitative measure of
the branch predictor's effectiveness."

### Q: How does this relate to real CPUs?
**A:** "Modern CPUs like Intel's Core series use much deeper pipelines (14-20+
stages) and more sophisticated predictors (TAGE, perceptron-based). The penalty
can be 15-20 cycles. Our implementation demonstrates the core mechanism at an
educational scale — speculate, execute, detect, recover."

---

## 9. File Structure
```
speculative_mips/
├── rtl/
│   ├── branch_predictor.sv     — 2-bit BHT predictor + BTB
│   ├── pc_control.sv           — PC selection + flush trigger
│   ├── flush_control.sv        — Pipeline flush FSM
│   ├── performance_counter.sv  — Branch statistics tracker
│   └── mips_pipeline.sv        — Top-level 5-stage pipeline
├── tb/
│   └── tb_mips_pipeline.sv     — Testbench (2 test cases)
├── sim/
│   └── waves.vcd               — Generated after simulation
├── docs/
│   └── README.md               — This file
└── Makefile
```

---

*Project: Speculative Execution with Branch Prediction and Pipeline Recovery in a 5-Stage MIPS Processor*

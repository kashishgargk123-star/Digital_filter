# Task 4 — Digital FIR Filter Design

**ELiteTEch Intern — VLSI Internship**

A 4-tap Finite Impulse Response (FIR) low-pass filter, implemented in
Verilog with fixed coefficients, verified with a testbench, and
analyzed for performance.

## Files

| File | Description |
|---|---|
| `fir_filter.v` | RTL design — the FIR filter module |
| `tb_fir_filter.v` | Testbench — impulse, step, and oscillating-input tests |
| `performance_analysis.md` | Simulation results and performance analysis report |
| `README.md` | This file |

## Filter Overview

- **Type:** 4-tap FIR, direct form
- **Coefficients:** h = [1, 3, 3, 1] (fixed, sum = 8)
- **Equation:** `y[n] = ( x[n] + 3*x[n-1] + 3*x[n-2] + x[n-3] ) / 8`
- **Data width:** 8-bit signed
- **Latency:** 1 clock cycle
- **Throughput:** 1 sample per clock cycle (fully pipelined)

This coefficient set is the expansion of `(1 + z⁻¹)³`, giving a smooth
low-pass response with unity DC gain and a null at the Nyquist
frequency — see `performance_analysis.md` for the simulation results
that confirm this.

## Module Ports (`fir_filter`)

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | input | 1 | Clock |
| `rst_n` | input | 1 | Active-low synchronous reset |
| `valid_in` | input | 1 | New input sample available |
| `data_in` | input | 8 (signed) | Input sample x[n] |
| `valid_out` | output | 1 | Output sample available |
| `data_out` | output | 8 (signed) | Filtered output y[n] |

## How to Run

Requires [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog` +
`vvp`), and optionally [GTKWave](http://gtkwave.sourceforge.net/) to
view waveforms.

```bash
# Compile
iverilog -o sim_out fir_filter.v tb_fir_filter.v

# Run the simulation
vvp sim_out

# (Optional) view the generated waveform
gtkwave fir_filter.vcd
```

## Expected Results

| Test | Input | Output |
|---|---|---|
| Impulse response | 16, 0, 0, 0, 0, 0 | 2, 6, 6, 2, 0, 0 |
| Step response | 10, 10, 10, 10, 10, 10 | 1, 5, 8, 10, 10, 10 |
| Oscillating (Nyquist) input | 20, -20, 20, -20, ... | 2, 5, 2, 0, 0, 0, ... |

Full explanation of each result is in `performance_analysis.md`.

## Notes

- Coefficients (1, 3, 3, 1) are powers-of-two-friendly, so no true
  hardware multipliers are needed — synthesis tools will implement
  the ×1 and ×3 multiplies as shifts/shift-adds.
- The `/8` normalization is done as an arithmetic right shift by 3.

  ## Author
  Kashish

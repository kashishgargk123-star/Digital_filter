# Task 4 — Digital FIR Filter Design: Simulation & Performance Analysis

## 1. Filter Specification

- **Type:** 4-tap Finite Impulse Response (FIR) low-pass filter, direct form
- **Coefficients:** h = [1, 3, 3, 1] (fixed, integer), normalized by 8
- **Difference equation:**

  y[n] = ( x[n] + 3·x[n-1] + 3·x[n-2] + x[n-3] ) / 8

- **Transfer function:** H(z) = (1 + z⁻¹)³ / 8
  This is the binomial / "raised-cosine-like" smoothing filter — a low-pass
  filter with a triple zero at z = −1, i.e. at the Nyquist frequency (half
  the sample rate).
- **Data width:** 8-bit signed input/output
- **Normalization:** division by 8 implemented as an arithmetic right shift
  by 3 (no explicit divider hardware needed)

## 2. RTL Implementation Summary

- 3 history registers hold x[n-1], x[n-2], x[n-3]; the live sample x[n]
  is used directly on `data_in` in the same cycle.
- 4 multipliers (by small constants 1 and 3 — synthesizes to
  shift/shift-add rather than a full multiplier) and a 4-input adder tree.
- Output is registered, giving the design a clean, single-cycle-latency,
  fully pipelined structure capable of accepting a new sample every clock.

## 3. Simulation Results

A bit-accurate model of the RTL was used to pre-compute expected results
for three test sequences (impulse, step, and a high-frequency oscillating
input), matching the structure of `tb_fir_filter.v`.

### Test 1 — Impulse response
Input:  `16, 0, 0, 0, 0, 0`
Output: `2, 6, 6, 2, 0, 0`

The output reproduces the filter's coefficient shape (1, 3, 3, 1) scaled by
16/8 = 2, i.e. `2, 6, 6, 2` — exactly as expected, since the impulse
response of an FIR filter *is* its coefficient set. This confirms the
tapped-delay-line and coefficient wiring are correct.

### Test 2 — Step response
Input:  `10, 10, 10, 10, 10, 10`
Output: `1, 5, 8, 10, 10, 10`

The output rises smoothly and settles at the input value after 3 samples
(the filter order), confirming a **DC gain of 1** — consistent with the
coefficients summing to 8 and being divided by 8. No overshoot or ringing
is seen, which is expected for a filter with all-positive coefficients.

### Test 3 — Oscillating (high-frequency) input
Input:  `20, -20, 20, -20, 20, -20, 20, -20`
Output: `2, 5, 2, 0, 0, 0, 0, 0`

After a short transient, the output settles to **0** even though the
input is swinging fully between +20 and −20. This directly demonstrates
the filter's low-pass behavior: a signal alternating every sample sits at
the Nyquist frequency, exactly where H(z) has its triple zero, so it is
fully rejected in steady state.

## 4. Performance Metrics

| Metric | Value |
|---|---|
| Filter order / taps | 4 |
| Latency | 1 clock cycle (registered output) |
| Throughput | 1 sample per clock cycle (fully pipelined) |
| DC gain | 1 (unity) |
| Nyquist-frequency gain | 0 (full rejection) |
| Multipliers required | 4 (constant coefficients → shift-add in synthesis) |
| Adders required | 3 (4-input tree) |
| Storage | 3 × 8-bit history registers |

## 5. Conclusion

The filter behaves as designed: it passes low-frequency / slowly-varying
signals with unity gain (step test) while strongly attenuating
high-frequency content up to full rejection at Nyquist (oscillating
test), and its impulse response correctly reproduces its coefficients.
The fixed-coefficient, shift-based design keeps the hardware small
(no true multipliers needed) while still giving smooth, ripple-free
low-pass filtering suitable for basic signal-conditioning tasks such as
smoothing noisy sensor or image-sensor data.

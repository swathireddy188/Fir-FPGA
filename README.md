# Parameterized FIR Filter — FPGA (SystemVerilog)

A streaming, synthesizable **FIR (Finite Impulse Response) digital filter** for
Xilinx Artix-7 / Vivado, with a self-checking **Questa/ModelSim** testbench and a
**Python golden reference model**. The canonical FPGA-DSP building block, built to
demonstrate RTL design, verification, and DSP fundamentals end to end.

---

## What an FIR filter does

It smooths or shapes a stream of samples by taking a weighted sum of the current and
previous inputs:

```
y[n] = COEFFS[0]*x[n] + COEFFS[1]*x[n-1] + ... + COEFFS[N-1]*x[n-(N-1)]
```

The coefficients define the response (low-pass, high-pass, band-pass...). Change only
the coefficients and the same hardware becomes a different filter. Real applications:
de-noising a sampled sensor or voltage-rail reading, anti-aliasing, audio shaping.

---

## Design

- Parameterized: `DATA_WIDTH`, `COEFF_WIDTH`, `N_TAPS`, coefficients.
- Fully **signed** arithmetic; **full-precision** output (no rounding), so it matches
  the golden model bit-for-bit.
- Streaming interface: assert `in_valid` with a sample, get `out_valid` + `out_data`
  one clock later (1-cycle latency).
- 8-tap symmetric smoothing coefficients by default: `{1,2,3,4,4,3,2,1}`.

```
 in_data ─►[ x[n] | x[n-1] | ... | x[n-7] ]   tapped delay line
              │       │            │
            ×c0     ×c1    ...    ×c7          multiply
              └───────┴──── + ─────┘          accumulate
                          │
                       out_data
```

---

## Files

```
fir-fpga/
├── rtl/fir_filter.sv          synthesizable FIR (the design)
├── tb/fir_filter_tb.sv        self-checking testbench
├── model/fir_golden.py        Python reference model (generates expected values)
├── constraints/fir_filter.xdc Artix-7 timing constraints
└── README.md
```

---

## How to verify (the workflow that matters)

The trustworthy way to build hardware DSP: an **independent golden model** computes the
correct answer, and the testbench checks the RTL against it. Here that model is Python
(it would be MATLAB in many shops — same idea).

**1. Generate verified expected values:**

```bash
python3 model/fir_golden.py
```

This prints the stimulus and the exact expected outputs (already embedded in the
testbench).

**2. Simulate in Questa / ModelSim:**

```bash
vlog rtl/fir_filter.sv tb/fir_filter_tb.sv
vsim -c work.fir_filter_tb -do "run -all; quit"
```

**3. Or simulate in Vivado (xsim):**

```bash
xvlog -sv rtl/fir_filter.sv tb/fir_filter_tb.sv
xelab fir_filter_tb -R
```

Expected result: every sample prints `OK` and the summary reads `RESULT: PASS`.
The impulse at the start produces the coefficients scaled by the impulse value
(50 → 50,100,150,200,200,150,100,50) — a quick visual proof the filter is correct.

---

## How to synthesize (Vivado)

1. Create a project targeting your Artix-7 part (e.g. xc7a35t for Arty A7).
2. Add `rtl/fir_filter.sv` as a design source and `constraints/fir_filter.xdc`.
3. Fill in the board-specific pin LOCs in the XDC.
4. Run synthesis and implementation, then check the timing report for positive WNS
   (worst negative slack) — that's your timing-closure proof, the same metric you hit
   on the UART project.

---

## Swapping in a real filter (the DSP extension)

The default coefficients are a simple smoother. For a real low-pass filter, generate
coefficients with a DSP tool and quantize them to integers:

- MATLAB: `b = fir1(7, 0.25); coeffs = round(b * 64);`
- Python: `from scipy.signal import firwin; coeffs = np.round(firwin(8, 0.25)*64)`

Put the integer coefficients in **both** `fir_golden.py` (`COEFFS`) and the RTL
`COEFFS` parameter, re-run the golden model to refresh the expected values, and
re-simulate. The hardware never changes — only the numbers.

---

## Skills demonstrated

SystemVerilog RTL design, parameterization, signed fixed-point arithmetic, streaming
valid interfaces, self-checking testbenches, golden-model verification, FIR/DSP theory,
and the Vivado synthesis + timing-closure flow on Artix-7.

---

## Where it goes next

- Pipeline the multiply-accumulate for higher clock rates (one adder stage per tap)
- Use a symmetric-FIR fold to halve the multipliers
- Wrap in an AXI4-Stream interface for SoC integration
- Add a UVM testbench (closes the UVM gap on the same, already-verified design)
"# Fir-FPGA" 

"""
fir_golden.py  --  the reference model (this is your DSP / MATLAB gap, in Python).

A hardware DSP block is only trustworthy if you have an independent "golden"
model that computes what the right answer should be. In industry that's often
MATLAB; here it's Python (numpy-free, so it runs anywhere). The RTL and this
model use the SAME integer coefficients, so their outputs match bit-for-bit.

This script:
  1. defines the FIR coefficients,
  2. defines a test stimulus (impulse, step, ramp),
  3. computes the exact integer FIR output,
  4. prints the stimulus and expected outputs in a form you can paste straight
     into the SystemVerilog testbench.

FIR maths:   y[n] = sum(k=0..N-1)  coeff[k] * x[n-k]      (x[<0] = 0)
"""

# 8-tap symmetric low-pass-ish smoothing filter (integer coefficients).
# Swap these for real MATLAB/scipy firwin() coefficients later — the RTL
# doesn't change, only this array and the testbench's expected values.
COEFFS = [1, 2, 3, 4, 4, 3, 2, 1]          # sum = 20
N = len(COEFFS)

# Test stimulus: an impulse, then a step up, then back down, then a short ramp.
# Signed 8-bit range is -128..127.
STIMULUS = [
    50, 0, 0, 0, 0,        # impulse -> output is the scaled impulse response
    100, 100, 100, 100,    # step up -> output ramps to steady-state gain
    0, 0, 0, 0,            # step down -> output decays
    10, 20, 30, 40, 50,    # ramp
    -40, -40, 0, 0, 0,     # negative step (checks signed arithmetic)
]


def fir(stimulus, coeffs):
    """Full-precision integer FIR. Returns the output sample list."""
    n = len(coeffs)
    out = []
    for i in range(len(stimulus)):
        acc = 0
        for k in range(n):
            x = stimulus[i - k] if (i - k) >= 0 else 0
            acc += coeffs[k] * x
        out.append(acc)
    return out


def main():
    expected = fir(STIMULUS, COEFFS)

    print(f"// Coefficients : {COEFFS}  (sum={sum(COEFFS)})")
    print(f"// N taps       : {N}")
    print(f"// Samples      : {len(STIMULUS)}")
    print()
    print("// --- paste into the testbench ---")
    print(f"localparam int N_SAMPLES = {len(STIMULUS)};")
    print("localparam logic signed [7:0] STIMULUS [0:N_SAMPLES-1] = '{")
    print("    " + ", ".join(str(v) for v in STIMULUS))
    print("};")
    print("localparam int signed EXPECTED [0:N_SAMPLES-1] = '{")
    print("    " + ", ".join(str(v) for v in expected))
    print("};")
    print()
    print("// human-readable check table:")
    print("//  idx   x[n]   y[n]")
    for i, (x, y) in enumerate(zip(STIMULUS, expected)):
        print(f"//  {i:3d}  {x:5d}  {y:6d}")


if __name__ == "__main__":
    main()

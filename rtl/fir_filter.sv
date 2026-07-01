// ============================================================================
// fir_filter.sv  --  Parameterized FIR (Finite Impulse Response) digital filter
//
// A streaming, synthesizable FIR filter for Artix-7 / Vivado.
//   y[n] = sum(k=0..N-1) COEFFS[k] * x[n-k]
//
// One sample in (when in_valid), one filtered sample out (out_valid),
// with a 1-cycle latency. Fully signed. Output is full precision (no
// rounding) so it matches the Python/MATLAB golden model bit-for-bit.
//
// To change the filter response, change only the COEFFS parameter (e.g. drop
// in coefficients from MATLAB fir1() or scipy.signal.firwin()). The hardware
// is unchanged.
// ============================================================================
module fir_filter #(
    parameter int DATA_WIDTH  = 8,                 // input sample width (signed)
    parameter int COEFF_WIDTH = 8,                 // coefficient width (signed)
    parameter int N_TAPS      = 8,                 // number of taps
    // accumulator must be wide enough to never overflow:
    //   data + coeff + room for summing N products
    parameter int ACC_WIDTH   = DATA_WIDTH + COEFF_WIDTH + $clog2(N_TAPS),
    // filter coefficients (must have N_TAPS entries)
    parameter logic signed [COEFF_WIDTH-1:0] COEFFS [0:N_TAPS-1] =
        '{ 8'sd1, 8'sd2, 8'sd3, 8'sd4, 8'sd4, 8'sd3, 8'sd2, 8'sd1 }
)(
    input  logic                          clk,
    input  logic                          rst_n,     // active-low reset
    input  logic                          in_valid,
    input  logic signed [DATA_WIDTH-1:0]  in_data,
    output logic                          out_valid,
    output logic signed [ACC_WIDTH-1:0]   out_data
);

    // tapped delay line (shift register of past samples)
    logic signed [DATA_WIDTH-1:0] sample_reg [0:N_TAPS-1];

    // next state of the delay line: shift in the new sample at tap 0
    logic signed [DATA_WIDTH-1:0] next_samples [0:N_TAPS-1];

    always_comb begin
        for (int k = 0; k < N_TAPS; k++) begin
            if (k == 0)
                next_samples[k] = in_valid ? in_data : sample_reg[0];
            else
                next_samples[k] = in_valid ? sample_reg[k-1] : sample_reg[k];
        end
    end

    // multiply-accumulate over the (about to be updated) delay line
    logic signed [ACC_WIDTH-1:0] acc;
    always_comb begin
        acc = '0;
        for (int k = 0; k < N_TAPS; k++) begin
            acc += COEFFS[k] * next_samples[k];
        end
    end

    // register the delay line and the output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < N_TAPS; k++)
                sample_reg[k] <= '0;
            out_data  <= '0;
            out_valid <= 1'b0;
        end else begin
            for (int k = 0; k < N_TAPS; k++)
                sample_reg[k] <= next_samples[k];
            out_data  <= acc;
            out_valid <= in_valid;     // out_valid follows in_valid by 1 cycle
        end
    end

endmodule

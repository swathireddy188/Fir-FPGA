// ============================================================================
// fir_filter_tb.sv  --  Self-checking testbench for fir_filter
//
// Drives the exact stimulus from the Python golden model (model/fir_golden.py)
// and checks every output sample against the verified EXPECTED vector. Prints
// a per-sample table and a final PASS/FAIL summary.
//
// Run in Questa/ModelSim:
//     vlog rtl/fir_filter.sv tb/fir_filter_tb.sv
//     vsim -c work.fir_filter_tb -do "run -all; quit"
//
// Run in Vivado simulator (xsim):
//     xvlog -sv rtl/fir_filter.sv tb/fir_filter_tb.sv
//     xelab fir_filter_tb -R
// ============================================================================
`timescale 1ns/1ps

module fir_filter_tb;

    localparam int DATA_WIDTH  = 8;
    localparam int COEFF_WIDTH = 8;
    localparam int N_TAPS      = 8;
    localparam int ACC_WIDTH   = DATA_WIDTH + COEFF_WIDTH + $clog2(N_TAPS);

    // ---- golden vectors (generated and verified by model/fir_golden.py) ----
    localparam int N_SAMPLES = 23;
    localparam logic signed [7:0] STIMULUS [0:N_SAMPLES-1] = '{
        50, 0, 0, 0, 0, 100, 100, 100, 100, 0, 0, 0, 0,
        10, 20, 30, 40, 50, -40, -40, 0, 0, 0
    };
    localparam int EXPECTED [0:N_SAMPLES-1] = '{
        50, 100, 150, 200, 200, 250, 400, 650, 1000, 1300, 1400, 1300, 1000,
        610, 340, 200, 200, 340, 410, 390, 300, 120, -60
    };

    // ---- DUT signals ----
    logic                          clk = 0;
    logic                          rst_n;
    logic                          in_valid;
    logic signed [DATA_WIDTH-1:0]  in_data;
    logic                          out_valid;
    logic signed [ACC_WIDTH-1:0]   out_data;

    // ---- clock: 100 MHz ----
    always #5 clk = ~clk;

    // ---- DUT ----
    fir_filter #(
        .DATA_WIDTH (DATA_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .N_TAPS     (N_TAPS)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .in_valid  (in_valid),
        .in_data   (in_data),
        .out_valid (out_valid),
        .out_data  (out_data)
    );

    // ---- scoreboard ----
    int errors   = 0;
    int out_idx  = 0;

    // check each output sample as it appears
    always_ff @(posedge clk) begin
        if (out_valid) begin
            if (out_idx < N_SAMPLES) begin
                if (out_data === EXPECTED[out_idx]) begin
                    $display("  [%2d]  x=%4d  y=%6d   OK",
                             out_idx, STIMULUS[out_idx], out_data);
                end else begin
                    $display("  [%2d]  x=%4d  y=%6d   MISMATCH (expected %0d)",
                             out_idx, STIMULUS[out_idx], out_data, EXPECTED[out_idx]);
                    errors++;
                end
                out_idx++;
            end
        end
    end

    // ---- stimulus ----
    initial begin
        $display("==================================================");
        $display(" FIR FILTER TESTBENCH");
        $display("==================================================");

        // reset
        rst_n    = 0;
        in_valid = 0;
        in_data  = 0;
        repeat (3) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // drive one stimulus sample per clock
        for (int i = 0; i < N_SAMPLES; i++) begin
            in_valid <= 1;
            in_data  <= STIMULUS[i];
            @(posedge clk);
        end
        in_valid <= 0;
        in_data  <= 0;

        // let the pipeline drain
        repeat (4) @(posedge clk);

        // ---- summary ----
        $display("--------------------------------------------------");
        if (out_idx != N_SAMPLES)
            $display(" WARNING: got %0d outputs, expected %0d", out_idx, N_SAMPLES);
        if (errors == 0)
            $display(" RESULT: PASS  (%0d/%0d samples correct)", out_idx, N_SAMPLES);
        else
            $display(" RESULT: FAIL  (%0d mismatches)", errors);
        $display("==================================================");
        $finish;
    end

endmodule

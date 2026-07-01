# ============================================================================
# fir_filter.xdc  --  Artix-7 constraints (Vivado)
#
# Timing constraint for a 100 MHz system clock. Pin LOC/IOSTANDARD assignments
# are board-specific (e.g. Arty A7, Basys 3, Nexys A7) -- fill in the LOC values
# from your board's master XDC, then uncomment.
# ============================================================================

# ---- 100 MHz clock (10 ns period) ----
create_clock -name sys_clk -period 10.000 [get_ports clk]

# ---- example pin assignments (edit LOC for YOUR board, then uncomment) ----
# set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports clk]
# set_property -dict { PACKAGE_PIN C2  IOSTANDARD LVCMOS33 } [get_ports rst_n]
# set_property -dict { PACKAGE_PIN D9  IOSTANDARD LVCMOS33 } [get_ports in_valid]
# set_property -dict { PACKAGE_PIN A8  IOSTANDARD LVCMOS33 } [get_ports out_valid]

# ---- input/output delays (adjust to your interface budget) ----
# set_input_delay  -clock sys_clk 2.000 [get_ports {in_data[*] in_valid}]
# set_output_delay -clock sys_clk 2.000 [get_ports {out_data[*] out_valid}]

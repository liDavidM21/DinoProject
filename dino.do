vlib work

# Compile all Verilog modules in poly_function to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns DinoMove.v

# Load simulation using part2 as the top level simulation module.
vsim test
# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}


# first test case	
force {clk} 0
force {KEY[0]} 0
run 10ns

force {clk} 1
force {KEY[0]} 0
run 10ns	

force {clk} 0
force {KEY[0]} 1
force {KEY[1]} 0
run 10ns


force {clk} 1
force {KEY[0]} 1
force {KEY[1]} 0
run 10ns

force {KEY[1]} 1
force {clk} 0
run 10ns
force {KEY[1]} 0
force {clk} 1
run 10ns

force {clk} 0 0, 1 5 -r 10
run 80000ns
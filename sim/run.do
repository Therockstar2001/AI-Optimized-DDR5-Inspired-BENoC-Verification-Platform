vlib work
vmap work work

vlog -sv -f filelist.f

vsim -voptargs=+acc work.top_tbs

add wave -r *

run -all
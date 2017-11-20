transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+F:/Unum/unumIII_32_3_adder_pipline4/Unum_32bit_3_adder {F:/Unum/unumIII_32_3_adder_pipline4/Unum_32bit_3_adder/unum_adder.v}

vlog -vlog01compat -work work +incdir+F:/Unum/unumIII_32_3_adder_pipline4/Unum_32bit_3_adder/simulation/modelsim {F:/Unum/unumIII_32_3_adder_pipline4/Unum_32bit_3_adder/simulation/modelsim/unum_adder.vt}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  unum_adder_vlg_tst

add wave *
view structure
view signals
run 10 ps

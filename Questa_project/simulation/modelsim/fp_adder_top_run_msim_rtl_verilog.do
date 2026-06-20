transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+A:/Desktop/Floating_point_adder/Modules {A:/Desktop/Floating_point_adder/Modules/round_pkg.sv}
vlog -sv -work work +incdir+A:/Desktop/Floating_point_adder/Modules {A:/Desktop/Floating_point_adder/Modules/norm_adder.sv}
vlog -sv -work work +incdir+A:/Desktop/Floating_point_adder/Modules {A:/Desktop/Floating_point_adder/Modules/mantissa_calc.sv}
vlog -sv -work work +incdir+A:/Desktop/Floating_point_adder/Modules {A:/Desktop/Floating_point_adder/Modules/lzc.sv}
vlog -sv -work work +incdir+A:/Desktop/Floating_point_adder/Modules {A:/Desktop/Floating_point_adder/Modules/fp_adder_top.sv}
vlog -sv -work work +incdir+A:/Desktop/Floating_point_adder/Modules {A:/Desktop/Floating_point_adder/Modules/fp_adder.sv}
vlog -sv -work work +incdir+A:/Desktop/Floating_point_adder/Modules {A:/Desktop/Floating_point_adder/Modules/exponent_calc.sv}
vlog -sv -work work +incdir+A:/Desktop/Floating_point_adder/Modules {A:/Desktop/Floating_point_adder/Modules/round_adder.sv}
vlog -sv -work work +incdir+A:/Desktop/Floating_point_adder/Modules {A:/Desktop/Floating_point_adder/Modules/exception_adder.sv}


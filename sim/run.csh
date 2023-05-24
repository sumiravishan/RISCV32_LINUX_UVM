#!/usr/bin/csh -f 
rm -rf xvlog*
rm -rf xelab*
rm -rf xsim*
rm -rf work*
xvlog -sv -L uvm -i ../src ../src/riscv_uvm_model_pkg.sv ../src/riscv_core_uvm_run.sv
xelab -L uvm riscv_core_uvm_run -debug all
xsim work.riscv_core_uvm_run -R

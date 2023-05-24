module riscv_core_uvm_run;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import riscv_uvm_model_pkg::*;
	
	initial begin 
		run_test("riscv_core");
		#1;
	end 
	
	final begin 
		$display("Max Size = %0h",riscv_memory::max_size);
	end 
endmodule

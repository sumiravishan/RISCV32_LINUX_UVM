/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Author: Sumira Fernando                                    ////
////          k.w.s.v.fernando@gmail.com                         ////
////                                                             ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2023                                          ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
//// This source file is free software; you can redistribute it  ////
//// and/or modify it under the terms of the GNU Lesser General  ////
//// Public License as published by the Free Software Foundation.////
////                                                             ////
//// This source is distributed in the hope that it will be      ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied  ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR     ////
//// PURPOSE.  See the GNU Lesser General Public License for more////
//// details. http://www.gnu.org/licenses/lgpl.html              ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
class csr_registers extends uvm_object;
	bit [31:0] csr[4095:0];
	
	`uvm_object_utils_begin(csr_registers)
		`uvm_field_sarray_int(csr,UVM_ALL_ON)
	`uvm_object_utils_end 

	function new(string name = "" );
		super.new(name);
	endfunction
	
	function bit [31:0] read_csr(bit [11:0] addr );
			return csr[addr];
	endfunction
	function void write_csr(bit [11:0] addr, bit [31:0] data );
			csr[addr] = data;
	endfunction 
endclass

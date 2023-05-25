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
class base_isa_register_set extends uvm_object;
	int unsigned PC;
	bit [31:0] x[31:0];
	
	`uvm_object_utils_begin(base_isa_register_set)
		`uvm_field_int(PC,UVM_ALL_ON)
		`uvm_field_sarray_int(x,UVM_ALL_ON)
	`uvm_object_utils_end 

	function new(string name = "" );
		super.new(name);
	endfunction
	
	function bit [31:0] read_x(bit [4:0] addr );
		if ( addr == 0 ) begin 
			return 0;
		end else begin 
			return x[addr];
		end 
	
	endfunction
	function void write_x(bit [4:0] addr, bit [31:0] data );
		if ( addr != 0 ) begin 
			x[addr] = data;
		end
	endfunction 
endclass

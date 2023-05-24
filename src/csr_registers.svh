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

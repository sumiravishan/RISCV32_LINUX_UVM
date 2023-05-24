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

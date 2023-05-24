class riscv_memory extends uvm_component;
	bit [31:0] mem[int unsigned];
	
	static int max_size;
	
	`uvm_component_utils(riscv_memory)

	function new(string name,uvm_component parent );
		super.new(name,parent);
	endfunction
	
	function bit [7:0] get_byte(int unsigned addr );
		if ( mem.exists(addr) ) return mem[addr];
		return 0;
	endfunction
	function void set_byte(int unsigned addr, bit [7:0] data );
			if ( data !=0 ) begin 
				mem[addr] = data;
			end else if ( mem.exists(addr) ) begin 
				mem.delete(addr);
			end 
			if ( int'(mem.size()) > max_size ) begin 
				max_size = mem.size() ;
			end 
	endfunction 
	
	function bit [31:0] mem_read_req(int unsigned start_addr,mem_byte_size mem_bytes,sign_format sign=no_sign_Ext);
		mem_read_req = 0;
		case(mem_bytes)
			bytes2: begin 
				mem_read_req[7:0] = get_byte(start_addr);
				mem_read_req[15:8] = get_byte(start_addr+1);
				if ( sign == sign_Ext ) begin 
					mem_read_req[31:16] = {16{mem_read_req[15]}};
				end 
			end 
			bytes4: begin 
				mem_read_req[7:0] = get_byte(start_addr);
				mem_read_req[15:8] = get_byte(start_addr+1);
				mem_read_req[23:16] = get_byte(start_addr+2);
				mem_read_req[31:24] = get_byte(start_addr+3);
			end 	
			default: begin 
				mem_read_req[7:0] = get_byte(start_addr);
				if ( sign == sign_Ext ) begin 
					mem_read_req[31:8] = {24{mem_read_req[7]}};
				end 
			end
		endcase
		//$display("memory_read => addr %0h , val =%0h ",start_addr, mem_read_req );
	endfunction
	
	function void mem_write_req(int unsigned start_addr,bit[31:0] data, mem_byte_size mem_bytes);
		case(mem_bytes)
			bytes2: begin 
				set_byte(start_addr,data[7:0]);
				set_byte(start_addr+1,data[15:8]);
			end
			bytes4: begin 
				set_byte(start_addr,data[7:0]);
				set_byte(start_addr+1,data[15:8]);
				set_byte(start_addr+2,data[23:16]);
				set_byte(start_addr+3,data[31:24]);
			end
			default: begin 
				set_byte(start_addr,data[7:0]);
			end
		endcase
	
	endfunction 
	

	function void load_memory(int unsigned start_addr,int unsigned end_addr,string path);
		int fd;
		int unsigned current_addr;
		bit [7:0] val;
		
		current_addr = start_addr;
	
		fd = $fopen(path,"r");
		
		while( ! $feof(fd) ) begin 
			$fscanf(fd,"%h\n",val);
			if ( val != 0 ) begin 
				mem[current_addr] = val;
			end 
			current_addr++;
			if ( current_addr >= end_addr ) break;
		end 
		$fclose(fd);
	endfunction 
	
endclass

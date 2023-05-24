class riscv_core extends uvm_test;
	`uvm_component_utils(riscv_core)
	
	riscv_memory ram;
	base_isa_register_set isa_base_regs;
	csr_registers CSRS;
	int unsigned ram_offset = 32'h80000000;
	int unsigned ram_size   = 32'h8000000;
	
	bit [31:0] mem_data;
	//execution_status exec_status;
	bit [63:0] timer;
	bit [31:0] elapse_time_us = 4;
	int unsigned PC_MAPPED;
	bit proceed;
	riscv_instruction riscv_ins;
	I_format I;
	S_format S;
	J_format J;
	B_format B;
	U_format U;
	R_format R;
	Ext_A_format Ext_A;
	Reg_M_Ext Ext_M;
	EXT_Zicsr_Ecall_Ebreak_format Ext_ZicsrEcallEbreak;
	bit detected_linux_login;
	bit after_login;
	bit [47:0] login_string;
	
	sign_format sign;
	load_funct3 lFunct3;
	store_funct3 sFunct3;
	branch_funct3 bFunct3;
	Imm_Comp_funct3 immFunct3;
	Reg_Comp_funct3 regFunct3;
	Reg_Ext_M_funct3 regExtMFunct3;
	
	SRI_funct sriFunct;
	Add_Sub_funct addSubFunct;
	SR_funct srFunct;
	EXT_Zicsr_Ecall_Ebreak_Funct Zicsr_Ecall_Ebreak_Funct;
	
	bit [31:0] sign_ext_operand, operand1,operand2, operand3;
	bit [63:0] operand1_64, operand2_64;
	bit [31:0] destination_address;
	bit [31:0] destination_address_nocorrection;
	bit [31:0] destination_value;	
	bit [63:0] destination_value_64;	
	mem_byte_size byte_size;
	
	bit [31:0] timermatchl, timermatchh;
	bit ext_A_reservation;
	bit [31:0] trap;
	
	bit goto_sleep;
	bit [1:0] mode;
	bit [31:0] return_value;
	
	
	function new(string name,uvm_component parent);
		super.new(name,parent);
	endfunction
	
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		ram = riscv_memory::type_id::create("ram",this);
		CSRS = csr_registers::type_id::create("CSRS",this);
		isa_base_regs = base_isa_register_set::type_id::create("isa_base_regs",this);
	endfunction
	
	
	extern function riscv_instruction get_next_instruction(int unsigned PC_MAPPED);
	extern function bit [31:0] ram_address_correction(bit [31:0] addr);
	extern function bit ram_address_within_range(bit[31:0] addr, mem_byte_size byte_size);
	extern function void handle_interrupts_and_traps();
	extern function void exec_jalr();
	extern function void exec_Zicsr_Ecall_Ebreak();
	extern function void exec_load();
	extern function void exec_store();
	extern function void exec_branch();
	extern function void exec_lui();
	extern function void exec_auipc();
	extern function void exec_jal();
	extern function void exec_rv32_ext_A();
	extern function void exec_Imm_Comp();
	extern function void exec_Reg_Comp();
	extern function bit[31:0] shift_signed32(bit [31:0] v1, bit [31:0] shift_val);
	extern function void core_exec();
	
	int debug_tmp_count=0;
	
	
	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		ram.load_memory(0,2894941,"../hex/linux.hex");
		ram.load_memory(16775488,16777023,"../hex/dtb.hex");
		mode = 3;
		isa_base_regs.write_x(11,32'h80fff940);
		isa_base_regs.PC = ram_offset;
		proceed = 1;
		fork
			begin 
				forever begin 
					core_exec();
					#1;					
					debug_tmp_count++;
				end
			end
			begin 
				#(80000*1024);			
			end
		join_any
		phase.drop_objection(this);		
	
	
	endtask
	
endclass
	
	
	
	
	
	
	
	
	
	

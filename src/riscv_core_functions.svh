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
function riscv_instruction riscv_core::get_next_instruction(int unsigned PC_MAPPED);
	get_next_instruction = ram.mem_read_req(PC_MAPPED,bytes4);
endfunction

function bit [31:0] riscv_core::ram_address_correction(bit [31:0] addr);
	return ( addr - ram_offset );
endfunction

function bit riscv_core::ram_address_within_range(bit[31:0] addr, mem_byte_size byte_size);
	return ( (addr >= 0) && ( addr <= ram_size - byte_size ) );
endfunction

function void riscv_core::handle_interrupts_and_traps();
	operand1 = CSRS.read_csr(addrMIP);
	operand2 = CSRS.read_csr(addrMIE);
	operand3 = CSRS.read_csr(addrMSTATUS);
	
	trap = ( operand1[7] & operand2[7] & operand3[3] ) == 1'b1 ? 32'h80000007 : trap; 
	
	if ( trap != 0 ) begin 
		CSRS.write_csr(addrMCAUSE,trap);
		if ( trap == 32'h80000007 ) begin 
			CSRS.write_csr(addrMTVAL,0);
		end else begin 
			CSRS.write_csr(addrMTVAL,isa_base_regs.PC);
		end
		
		CSRS.write_csr(addrMEPC, isa_base_regs.PC);
		
		operand1 = CSRS.read_csr(addrMSTATUS);
		operand2 = ( mode << 11 );
		operand2[7] = operand1[3]; 
		CSRS.write_csr(addrMSTATUS,operand2);
		isa_base_regs.PC = CSRS.read_csr(addrMTVEC);
		mode = 3;	
	
	end 
//FIXME: other interrupts and traps
endfunction

function void riscv_core::exec_jalr();
	I = riscv_ins.non_opcode;
	sign_ext_operand = {{20{I.imm[11]}},I.imm};
	destination_value = isa_base_regs.PC + 4;
	isa_base_regs.PC = isa_base_regs.read_x(I.rs1) + sign_ext_operand;
	isa_base_regs.write_x(I.rd,destination_value);

endfunction 

function void riscv_core::exec_Zicsr_Ecall_Ebreak();
	Ext_ZicsrEcallEbreak = riscv_ins.non_opcode;
	Zicsr_Ecall_Ebreak_Funct = EXT_Zicsr_Ecall_Ebreak_Funct'(Ext_ZicsrEcallEbreak.funct3);
	
	if ( Zicsr_Ecall_Ebreak_Funct == ecall_ebreak ) begin 
		if ( Ext_ZicsrEcallEbreak.csr == 0 ) begin 
			trap = mode > 0 ? 11 : 8 ; // no pc +4 here 		
		end else if ( Ext_ZicsrEcallEbreak.csr == 12'h105 ) begin 
			operand1 = CSRS.read_csr(addrMSTATUS) | 8 ;
			CSRS.write_csr(addrMSTATUS,operand1);
			goto_sleep = 1;
			isa_base_regs.PC = isa_base_regs.PC + 4;
			return_value = 1;
			return;
		
		end else if ( Ext_ZicsrEcallEbreak.csr[7:0] == 8'h02 ) begin 
			operand1 = CSRS.read_csr(addrMSTATUS);
			operand2 = ( (operand1 & 32'h80 ) >> 4 ) | ( mode << 11 ) | 32'h80 ;
			CSRS.write_csr(addrMSTATUS,operand2);
			mode = ( operand1 >> 11 ) & 3;
			isa_base_regs.PC = CSRS.read_csr(addrMEPC);
		end else begin 
			//FIXME: Trap 5
			isa_base_regs.PC = isa_base_regs.PC + 4;
		
		end
	end else if ( Zicsr_Ecall_Ebreak_Funct != CSRESERVE ) begin 
		if ( Zicsr_Ecall_Ebreak_Funct < CSRESERVE ) begin 
			operand1 = isa_base_regs.read_x(Ext_ZicsrEcallEbreak.rs1);
		end else begin 
			operand1 = Ext_ZicsrEcallEbreak.rs1;		
		end 
		
		case(Ext_ZicsrEcallEbreak.csr) 
			32'h300,32'h304,32'h305,32'h340,32'h341,32'h342,32'h343,32'h344,32'h3A0,32'h3B0,32'hC00,32'hF14: begin 
				destination_value = CSRS.read_csr(Ext_ZicsrEcallEbreak.csr);
				isa_base_regs.write_x(Ext_ZicsrEcallEbreak.rd,destination_value);
			end 
			default: begin 
				destination_value = 0;
				//FIXME: other CSR read
			end 
		endcase
		
		operand2 = 0;
		
		case(Zicsr_Ecall_Ebreak_Funct)
			CSRRW, CSRRWI: operand2 = operand1;
			CSRRS, CSRRSI: operand2 = operand1 | destination_value;
			CSRRC, CSRRCI: operand2 = (~operand1) & destination_value;
		
		endcase
		
		case(Ext_ZicsrEcallEbreak.csr)
			32'h300,32'h304,32'h305,32'h340,32'h341,32'h342,32'h343,32'h344: begin 
				CSRS.write_csr(Ext_ZicsrEcallEbreak.csr,operand2);
			end
		endcase
		
		isa_base_regs.PC = isa_base_regs.PC + 4;
	
	end else begin 
		//FIXME: trap2 
		isa_base_regs.PC = isa_base_regs.PC + 4;
	end

endfunction 

function void riscv_core::core_exec();

	operand1 = CSRS.read_csr(UR0_cycle);
	operand2 = CSRS.read_csr(UR0_cycleh);
	
	if ( ( {operand2,operand1} %1024 ) == 0 ) begin 
		timer = timer + elapse_time_us;
		CSRS.write_csr(UR0_time,timer[31:0]);
		CSRS.write_csr(UR0_timeh,timer[63:32]);
		operand1 = CSRS.read_csr(addrMIP);
		if ( ( timer != 0 ) && ( timer > {timermatchh,timermatchl} )) begin 
			goto_sleep = 0;
			operand1[7] = 1;
		end else begin 
			operand1[7] = 0;
		
		end 
		CSRS.write_csr(addrMIP,operand1);
	end 
	
	//$display("DEBUG1=>PC=%0h",isa_base_regs.PC);
	PC_MAPPED = ram_address_correction(isa_base_regs.PC);
	//$display("DEBUG1=>PC_MAPPED=%0h",PC_MAPPED);
	
	operand1 = CSRS.read_csr(UR0_cycle);
	operand2 = CSRS.read_csr(UR0_cycleh);
	operand1 = 1 + operand1;
	CSRS.write_csr(UR0_cycle,operand1);
	if ( operand1 == 0 ) begin 
		operand2 = 1+ operand2;
		CSRS.write_csr(UR0_cycleh,operand2);
	end 

	if ( proceed ) begin  
		trap = 0;
		//$display("DEBUG2=>PC_MAPPED=%0h",PC_MAPPED);
		riscv_ins = get_next_instruction(PC_MAPPED);
		//$display("DEBUG1=>riscv_ins=%0h",riscv_ins);
		case ( riscv_ins.opcode ) 
			Load: exec_load();
			Store: exec_store();
			Jal:  exec_jal();
			Jalr: exec_jalr();
			Lui:  exec_lui();
			Auipc: exec_auipc();
			RV32_Ext_A: exec_rv32_ext_A();
			Imm_Comp: exec_Imm_Comp();
			Reg_Comp: exec_Reg_Comp();
			Zicsr_Ecall_Ebreak: exec_Zicsr_Ecall_Ebreak();
			Branch: exec_branch();
			default: begin 
				//FIXME: wither unsupported or invalid
				isa_base_regs.PC = isa_base_regs.PC + 4;
			end 
		endcase 
		handle_interrupts_and_traps();
	
	end 

endfunction

function void riscv_core::exec_load();
	I = riscv_ins.non_opcode;
	sign = sign_format'(I.funct3[2]);
	lFunct3 = load_funct3'(I.funct3);
	sign_ext_operand = {{20{I.imm[11]}},I.imm};
	destination_address_nocorrection = sign_ext_operand + isa_base_regs.read_x(I.rs1);
	destination_address = ram_address_correction(destination_address_nocorrection);
	byte_size = ( lFunct3 == LW ) ? bytes4 : ( ( lFunct3 == LH ) || ( lFunct3 == LHU ) ) ? bytes2 : byte1;
	destination_value = 0;
	
	if ( ram_address_within_range(destination_address,byte_size) ) begin 
		if ( (  lFunct3 != LRESERVE1 ) && (  lFunct3 != LRESERVE2 ) && (  lFunct3 != LRESERVE3 ) ) begin 
			destination_value = ram.mem_read_req(destination_address,byte_size,sign);
			isa_base_regs.write_x(I.rd,destination_value);
		end else begin 
			//FIXME: Trap2 
		end 
	
	end else begin 
		if ( destination_address_nocorrection == 32'h1100bff8 ) begin //RTC 
			destination_value = CSRS.read_csr(UR0_time);
			isa_base_regs.write_x(I.rd,destination_value);
		end else if ( destination_address_nocorrection == 32'h1100bffc ) begin //RTC
			destination_value = CSRS.read_csr(UR0_timeh);
			isa_base_regs.write_x(I.rd,destination_value);
		end else if ( ( destination_address_nocorrection <= 32'h10000006 ) && ( destination_address_nocorrection >= 32'h10000000 ) ) begin 
			if ( destination_address_nocorrection == 32'h10000005 ) begin 
				if ( ( detected_linux_login == 1 ) && ( destination_address_nocorrection == 32'h10000005 ) ) begin 
					destination_value = 32'h61;
				end else begin 
					destination_value = 32'h60;
				end
			end else if ( ( destination_address_nocorrection == 32'h10000000 ) && ( detected_linux_login == 1 ) ) begin 
				destination_value = 32'h0A;
			end else begin 
				destination_value = 32'h0;
			end 
			isa_base_regs.write_x(I.rd,destination_value);
		end else begin 
			//FIXME: trap 5		
		end 
	end 
	
	isa_base_regs.PC = isa_base_regs.PC + 4;

endfunction 

function void riscv_core::exec_store();
	S = {riscv_ins.non_opcode[24:18],riscv_ins.non_opcode[4:0],riscv_ins.non_opcode[17:5]};
	sign = sign_Ext;
	sFunct3 = ( S.funct3 < SRESERVE ) ? store_funct3'(S.funct3) : SRESERVE;
	sign_ext_operand = {{20{S.imm[11]}},S.imm};
	destination_address_nocorrection = sign_ext_operand + isa_base_regs.read_x(S.rs1);
	destination_address = ram_address_correction(destination_address_nocorrection);
	byte_size = ( sFunct3 == SW ) ? bytes4 : ( sFunct3 == SH ) ? bytes2 : byte1; 
	destination_value = 0;
	
	if ( ram_address_within_range(destination_address,byte_size) ) begin 
		if ( sFunct3 != SRESERVE ) begin 
			destination_value = isa_base_regs.read_x(S.rs2);
			ram.mem_write_req(destination_address,destination_value,byte_size);
		
		end else begin 
			//FIXME: Trap 2
		end 
	
	end else begin 
		if ( destination_address_nocorrection == 32'h11004000 ) begin
			destination_value = isa_base_regs.read_x(S.rs2);
			timermatchl = destination_value;
		end else if ( destination_address_nocorrection == 32'h11004004 ) begin 
			destination_value = isa_base_regs.read_x(S.rs2);
			timermatchh = destination_value;
		end else if ( ( destination_address_nocorrection <= 32'h10000004 ) && ( destination_address_nocorrection >= 32'h10000000 ) ) begin 
			if ( destination_address_nocorrection == 32'h10000000 ) begin
				//Console 
				$write("%0s",isa_base_regs.read_x(S.rs2));
				//FIXME: login string
				login_string = ( login_string << 8 ) | isa_base_regs.read_x(S.rs2) & 48'hFF;
				if ( ( login_string == 48'h6c6f67696e3a ) && ( detected_linux_login == 0 ) ) begin 
					detected_linux_login = 1;
				end 
			
			end
		end else begin 
			//FIXME: Trap 5
		end 
	
	end 
	isa_base_regs.PC = isa_base_regs.PC + 4;
	
endfunction 


function void riscv_core::exec_branch();
	B = {riscv_ins.non_opcode[24],riscv_ins.non_opcode[0],riscv_ins.non_opcode[23:18],riscv_ins.non_opcode[4:1],riscv_ins.non_opcode[17:5]};
	sign_ext_operand = {{19{B.imm[12]}},B.imm,1'b0};
	destination_value = sign_ext_operand + isa_base_regs.PC; 
	
	operand1 = isa_base_regs.read_x(B.rs1);
	operand2 = isa_base_regs.read_x(B.rs2);
	bFunct3 = branch_funct3'(B.funct3);
	
	if ( ( bFunct3 != BRESERVE1 ) && ( bFunct3 != BRESERVE2 ) ) begin 
		case (bFunct3)
			BNE: isa_base_regs.PC = ( operand1 != operand2 ) ? destination_value : isa_base_regs.PC + 4;
			BLT: isa_base_regs.PC = ( signed'(operand1) < signed'(operand2) ) ? destination_value : isa_base_regs.PC + 4;
			BGE: isa_base_regs.PC = ( signed'(operand1) >= signed'(operand2) ) ? destination_value : isa_base_regs.PC + 4;
			BLTU: isa_base_regs.PC = ( operand1 < operand2 ) ? destination_value : isa_base_regs.PC + 4;
			BGEU: isa_base_regs.PC = ( operand1 >= operand2 ) ? destination_value : isa_base_regs.PC + 4;
			BEQ: isa_base_regs.PC = ( operand1 == operand2 ) ? destination_value : isa_base_regs.PC + 4;
			default: begin 
				//FIXME: Trap 2
				isa_base_regs.PC = isa_base_regs.PC + 4;
			end 
		endcase 
	end else begin 
		//FIXME: Trap 2
		isa_base_regs.PC = isa_base_regs.PC + 4;
	end 
	
	
endfunction 


function void riscv_core::exec_lui();
	U = riscv_ins.non_opcode;
	destination_value = {U.imm,{12{1'b0}}};
	isa_base_regs.write_x(U.rd,destination_value);
	isa_base_regs.PC = isa_base_regs.PC + 4;
endfunction 

function void riscv_core::exec_auipc();
	U = riscv_ins.non_opcode;
	destination_value = {U.imm,{12{1'b0}}};
	destination_value = isa_base_regs.PC + destination_value;
	isa_base_regs.write_x(U.rd,destination_value);
	isa_base_regs.PC = isa_base_regs.PC + 4;
endfunction 

function void riscv_core::exec_jal();
	J = {riscv_ins.non_opcode[24],riscv_ins.non_opcode[12:5],riscv_ins.non_opcode[13],riscv_ins.non_opcode[23:14],riscv_ins.non_opcode[4:0]};
	sign_ext_operand = {{11{J.imm[20]}},J.imm,1'b0};
	destination_value = isa_base_regs.PC + 4;
	isa_base_regs.write_x(J.rd,destination_value);
	isa_base_regs.PC = isa_base_regs.PC + sign_ext_operand;
endfunction 

function void riscv_core::exec_rv32_ext_A();
	Ext_A = riscv_ins.non_opcode;
	operand1 = isa_base_regs.read_x(Ext_A.rs2);
	destination_address_nocorrection = isa_base_regs.read_x(Ext_A.rs1);
	destination_address = ram_address_correction(destination_address_nocorrection);
	byte_size = bytes4;
	sign = no_sign_Ext;
	destination_value = 0;
	
	if ( ram_address_within_range(destination_address,byte_size) ) begin 
		if ( ( Ext_A.funct5 <= AMOXOR_W ) || ( Ext_A.funct5 == AMOOR_W ) || ( Ext_A.funct5 == AMOAND_W ) || ( Ext_A.funct5 == AMOMIN_W ) || ( Ext_A.funct5 == AMOMAX_W ) || ( Ext_A.funct5 == AMOMINU_W ) || ( Ext_A.funct5 == AMOMAXU_W ) ) begin 
			destination_value = ram.mem_read_req(destination_address,byte_size);
			case(Ext_A.funct5)
				AMOADD_W: operand2 = operand1 + destination_value;
				AMOSWAP: operand2 = operand1; 
				LR_W : ext_A_reservation = 1; // FIXME: store reserver address and check and if other therea writes to the address reservation get cancelled 
				SC_W : begin 
						destination_value = !ext_A_reservation;
						operand2 = operand1;
						if ( ext_A_reservation ) begin 
							ram.mem_write_req(destination_address,operand2,byte_size);
						end 
				end
				AMOXOR_W: operand2 = operand1 ^ destination_value;
				AMOOR_W: operand2 = operand1 | destination_value;
				AMOAND_W: operand2 = operand1 & destination_value;
				AMOMIN_W: operand2 = signed'(operand1) < signed'(destination_value) ? operand1 : destination_value ;
				AMOMAX_W: operand2 = signed'(operand1) > signed'(destination_value) ? operand1 : destination_value;
				AMOMINU_W: operand2 = operand1 < destination_value ? operand1 : destination_value;
				AMOMAXU_W: operand2 = operand1 > destination_value ? operand1 : destination_value;
			endcase

			if ( ( Ext_A.funct5 != LR_W ) && ( Ext_A.funct5 != SC_W ) ) begin 
				ram.mem_write_req(destination_address,operand2,byte_size);
			end 
			isa_base_regs.write_x(Ext_A.rd,destination_value);
		end else begin 
			//FIXME: Trap 2
		end 
	end else begin 
		//FIXME: Trap 5
	end 
	isa_base_regs.PC = isa_base_regs.PC + 4;	

endfunction 

function bit[31:0] riscv_core::shift_signed32(bit [31:0] v1, bit [31:0] shift_val);
	bit go;
	int i;
	bit [31:0] shift;
	shift = shift_val %32;
	go = 1;
	shift_signed32 = v1 >> shift; 
	if ( v1[31] == 1 ) begin 
		for ( i = 31; i >= 0; i-- ) begin 
			if ( go == 1 ) begin 
				if ( shift_signed32[i] == 1 ) begin 
					go = 0;
				end else begin 
					shift_signed32[i] = 1'b1;
				end 
			end 
		end 
	
	end 
endfunction 

function void riscv_core::exec_Imm_Comp();
	I = riscv_ins.non_opcode;
	operand1 = isa_base_regs.read_x(I.rs1);
	immFunct3 = Imm_Comp_funct3'(I.funct3);
	sriFunct = SRI_funct'(I.imm[10]);
	
	if ( ( immFunct3 == SRI ) || ( immFunct3 == SLLI ) ) begin 
		I.imm = I.imm & 12'h1f;
	end 
	sign_ext_operand = {{20{I.imm[11]}},I.imm};
	destination_value = 0;
	case(immFunct3) 
		ADDI: destination_value = operand1 + sign_ext_operand;
		SLLI: destination_value = operand1 << (sign_ext_operand % 32 );
		SLTI: destination_value = signed'(operand1) < signed'(sign_ext_operand);
		SLTIU: destination_value = operand1 < sign_ext_operand;
		XORI: destination_value = operand1 ^ sign_ext_operand;
		SRI:  begin 
			if ( sriFunct == SRAI ) begin 
				destination_value = shift_signed32(operand1,sign_ext_operand);
			end else begin 
				destination_value = operand1 >> ( sign_ext_operand % 32 );
			end 
		
		end 
		ORI: destination_value = operand1 | sign_ext_operand;
		ANDI: destination_value = operand1 & sign_ext_operand;
	endcase 
	
	isa_base_regs.write_x(I.rd,destination_value);
	isa_base_regs.PC = isa_base_regs.PC + 4;
endfunction 


function void riscv_core::exec_Reg_Comp();
	R = riscv_ins.non_opcode;
	operand1 = isa_base_regs.read_x(R.rs1);
	operand2 = isa_base_regs.read_x(R.rs2);
	Ext_M = ( R.funct7 == 7'b0000001 ) ? M_EXT : noM_EXT;
	
	regFunct3 = Reg_Comp_funct3'(R.funct3);
	srFunct = SR_funct'(R.funct7[5]);
	addSubFunct = Add_Sub_funct'(R.funct7[5]);
	regExtMFunct3 = Reg_Ext_M_funct3'(R.funct3);

	destination_value = 0;
	if ( Ext_M == noM_EXT ) begin 
		case(regFunct3) 
			ADD_SUB: begin 
				if ( addSubFunct == ADD ) begin 
					destination_value = operand1 + operand2;
				end else begin 
					destination_value = operand1 - operand2;
				end 
			end 
			SLL: destination_value = operand1 << (operand2 % 32 );
			SLT: destination_value = signed'(operand1) < signed'(operand2);
			SLTU: destination_value = operand1 < operand2;
			XOR_: destination_value = operand1 ^ operand2;
			SR:  begin 
				if ( sriFunct == SRAI ) begin 
					destination_value = shift_signed32(operand1,operand2);
				end else begin 
					destination_value = operand1 >> ( operand2 % 32 );
				end 
			
			end 
			OR_: destination_value = operand1 | operand2;
			AND_: destination_value = operand1 & operand2;
		endcase 
	end else begin 
		case(regExtMFunct3)
			MUL: destination_value = operand1 * operand2;
			MULH: begin 
				operand1_64 = signed'(operand1);
				operand2_64 = signed'(operand2);
				destination_value_64 = signed'(operand1_64 * operand2_64 ) ;
				destination_value_64 = destination_value_64 >> 32 ;
				destination_value = destination_value_64[31:0];
			end 
			MULHSU: begin 
				operand1_64 = signed'(operand1);
				operand2_64 = operand2;	
				destination_value_64 = signed'(operand1_64 * operand2_64 ) ;	
				destination_value_64 = destination_value_64 >> 32 ;
				destination_value = destination_value_64[31:0];
			end 
			MULHU: begin 
				operand1_64 = operand1;
				operand2_64 = operand2;	
				destination_value_64 = (operand1_64 * operand2_64 ) >> 32 ;		
				destination_value = destination_value_64[31:0];
			end 
			DIV: begin 
				if ( operand2 == 0 ) begin 
					destination_value = 32'hffffffff;
				end else begin 
					destination_value = signed'(operand1) / signed'(operand2) ;
				end 
			end 
			DIVU: begin 
				if ( operand2 == 0 ) begin 
					destination_value = 32'hffffffff;
				end else begin 
					destination_value = operand1 / operand2 ;
				end 		
			end 
			REM: begin 
				if ( operand2 == 0 ) begin 
					destination_value = 32'hffffffff;
				end else begin 
					destination_value = signed'(operand1) % signed'(operand2) ;
				end 
			end 
			REMU: begin 
				if ( operand2 == 0 ) begin 
					destination_value = 32'hffffffff;
				end else begin 
					destination_value = operand1 % operand2 ;
				end 			
			end 
		endcase
	end 
	
	isa_base_regs.write_x(R.rd,destination_value);
	isa_base_regs.PC = isa_base_regs.PC + 4;
endfunction 
